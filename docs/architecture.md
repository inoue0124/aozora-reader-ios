# アーキテクチャ設計書: 青空文庫リーダー v2

## 1. アーキテクチャ概要

```
┌──────────────────────────────────────────────────┐
│                   View Layer                      │
│  HomeScreen / SearchScreen / FavoritesScreen      │
│  WorkDetailScreen / AuthorDetailScreen            │
│  ReaderScreen / ReviewSheet                       │
├──────────────────────────────────────────────────┤
│                ViewModel Layer                    │
│  HomeViewModel / SearchViewModel / ...            │
│  (@Observable, @MainActor)                        │
├──────────────────────────────────────────────────┤
│                Service Layer                      │
│  CatalogService / TextFetchService                │
│  RecommendationService / SummaryService           │
│  ReadingHistoryService / CoverImageService        │
│  (actor-based singletons)                         │
├──────────────────────────────────────────────────┤
│               Data Layer                          │
│  SwiftData (ModelContainer)                       │
│  UserDefaults (ReadingSettings)                   │
│  Bundle JSON (catalog, summaries)                 │
│  Disk Cache (text files)                          │
└──────────────────────────────────────────────────┘
```

**依存方向**: View → ViewModel → Service → Data（一方向のみ）

## 2. レイヤー定義

### View Layer
- SwiftUI View のみ
- UI の描画とユーザーインタラクションの受付
- ViewModel を `@State` で保持、`@Bindable` でバインド
- SwiftData クエリは `@Query` で直接取得可（お気に入り一覧等の単純リスト）
- ビジネスロジックを含まない

### ViewModel Layer
- `@Observable` + `@MainActor` で宣言
- View の状態管理（ローディング、エラー、表示データ）
- Service 層を呼び出してデータ取得・加工
- SwiftData の `ModelContext` は `@Environment` 経由で View から受け取る

### Service Layer
- `actor` ベースのシングルトン
- データアクセスとビジネスロジック
- スレッドセーフな非同期処理
- キャッシュ管理

### Data Layer
- SwiftData: 永続化（お気に入り、しおり、レビュー、閲覧履歴、生成あらすじ）
- Bundle JSON: 読み取り専用マスターデータ（カタログ、固定あらすじ）
- UserDefaults: 軽量設定（読書設定）
- Disk Cache: テキストファイルキャッシュ

## 3. 主要コンポーネント

### 3.1 新規 Service

#### RecommendationService (actor)

おすすめ著者のスコアリングを担う。

```
入力: ReadingHistory + BookReview (SwiftData)
      ↓
スコアリング:
  - レビュー済み著者: rating × 3.0
  - 閲覧著者: min(viewCount, 5) × 1.0
  - 同分類ボーナス: +2.0
  - recencyDecay 適用
      ↓
出力: [RecommendedAuthor] (スコア降順、上位10件)
      ↓
フォールバック: 履歴3件未満 → 作品数上位著者
```

#### SummaryService (actor)

あらすじの取得と生成補完を担う。

```
入力: bookId
      ↓
1. Bundle JSON (summaries.json) 検索
   → ヒット → return
2. SwiftData (GeneratedSummary) 検索
   → ヒット → return
3. LLM API で生成
   → 成功 → SwiftData にキャッシュ + return
   → 失敗 → nil return
```

#### ReadingHistoryService (actor)

閲覧履歴の記録を担う。

```
入力: Book 情報
      ↓
SwiftData (ReadingHistory) に upsert:
  - 新規: viewCount = 1, lastViewedAt = now
  - 既存: viewCount += 1, lastViewedAt = now
```

### 3.2 既存 Service（変更なし）

| Service | 役割 |
|---------|------|
| CatalogService | バンドル JSON からカタログ読み込み・検索 |
| TextFetchService | 本文テキスト取得 + ディスクキャッシュ |
| CoverImageService | 表紙カラー生成 |

### 3.3 新規 ViewModel

#### HomeViewModel (@Observable, @MainActor)

```swift
@Observable
@MainActor
final class HomeViewModel {
    var continueReadingBooks: [Bookmark] = []
    var recommendedAuthors: [RecommendedAuthor] = []
    var recentReviews: [BookReview] = []
    var workTypeShelves: [WorkTypeShelf] = []
    var isLoading = false

    func load(modelContext:) async { ... }
}
```

## 4. データフロー

### 4.1 おすすめ著者の更新フロー

```
ユーザーが作品を閲覧
  → ReaderViewModel.onAppear
    → ReadingHistoryService.recordView(book)
      → SwiftData: ReadingHistory upsert

ユーザーがレビューを投稿
  → ReviewViewModel.saveReview()
    → SwiftData: BookReview upsert

ホーム画面表示
  → HomeViewModel.load()
    → RecommendationService.recommendAuthors(context)
      → ReadingHistory + BookReview をクエリ
      → スコアリング算出
      → [RecommendedAuthor] を返却
```

### 4.2 あらすじの取得フロー

```
作品詳細画面表示
  → WorkDetailViewModel.loadSummary(bookId)
    → SummaryService.summary(for: bookId)
      → 1. summaries.json チェック
      → 2. GeneratedSummary (SwiftData) チェック
      → 3. LLM API 生成 + キャッシュ
    → summary プロパティにセット
```

## 5. SwiftData コンテナ構成

```swift
.modelContainer(for: [
    FavoriteBook.self,
    Bookmark.self,
    BookReview.self,
    ReadingHistory.self,      // 新規
    GeneratedSummary.self,    // 新規
])
```

## 6. 並行性設計

| コンポーネント | 分離方式 | 理由 |
|---------------|---------|------|
| ViewModel | @MainActor | UI 更新をメインスレッドで保証 |
| CatalogService | actor | カタログデータへの排他アクセス |
| TextFetchService | actor | キャッシュ操作の排他制御 |
| RecommendationService | actor | スコア計算の排他制御 |
| SummaryService | actor | キャッシュ + API 呼び出しの排他制御 |
| ReadingHistoryService | actor | SwiftData 書き込みの排他制御 |
| Model (Struct) | Sendable | actor 境界を越えるデータ転送 |

## 7. テスト戦略

| レイヤー | テスト方式 | 優先度 |
|---------|-----------|--------|
| RecommendationService | ユニットテスト（スコアリングロジック） | 高 |
| SummaryService | ユニットテスト（フォールバック分岐） | 高 |
| ReadingHistoryService | ユニットテスト（upsert 動作） | 中 |
| HomeViewModel | ユニットテスト（棚構成ロジック） | 中 |
| WorkType 分類 | ユニットテスト（マッピングルール） | 中 |
| 画面遷移 | UI テスト | 低 |

## 8. 将来拡張ポイント

| 拡張 | 設計上の考慮 |
|------|-------------|
| 棚パーソナライズ | HomeViewModel の棚順序を設定可能に |
| レビュー共有 | BookReview を同期可能なモデルに拡張 |
| カタログ更新 | CatalogService にリモート取得パスを追加 |
| AI 表紙生成 | CoverImageService に画像生成 API パスを追加 |
| 分類精度向上 | WorkType マッピングを ML ベースに拡張 |
