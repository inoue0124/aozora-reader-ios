# 機能設計書: 青空文庫リーダー v2

## 1. 画面一覧

| # | 画面名 | 種別 | 概要 |
|---|--------|------|------|
| S1 | ホーム | Tab | 発見画面。棚（レール UI）を縦に並べて回遊を促す |
| S2 | 検索 | Tab | タイトル / 著者名で作品を検索 |
| S3 | お気に入り | Tab | お気に入り作品の一覧 |
| S4 | 作品詳細 | Push | あらすじ・レビュー・メタデータの表示、読書開始導線 |
| S5 | 著者詳細 | Push | 著者プロフィール・作品一覧 |
| S6 | 読書 | FullScreen | 縦書きページめくり / 横書きスクロール |
| S7 | 読書設定 | Sheet | フォント / 行間 / 余白 / テーマ設定 |
| S8 | レビュー投稿 | Sheet | 星評価 + コメント入力 |

## 2. 画面詳細設計

### S1: ホーム（発見画面）

**目的**: 検索せずに作品と出会える発見体験を提供する

**レイアウト**:
```
┌─────────────────────────────┐
│ 青空文庫リーダー        (nav)│
├─────────────────────────────┤
│ 📖 続きから読む              │
│ ┌────┐ ┌────┐ ┌────┐  →    │
│ │book│ │book│ │book│        │
│ └────┘ └────┘ └────┘        │
├─────────────────────────────┤
│ ✍️ おすすめ著者              │
│ ┌────┐ ┌────┐ ┌────┐  →    │
│ │auth│ │auth│ │auth│        │
│ └────┘ └────┘ └────┘        │
├─────────────────────────────┤
│ 📝 最近のレビュー            │
│ ┌────┐ ┌────┐ ┌────┐  →    │
│ │rev │ │rev │ │rev │        │
│ └────┘ └────┘ └────┘        │
├─────────────────────────────┤
│ 📚 短編 / 長編 / エッセイ …  │
│ ┌────┐ ┌────┐ ┌────┐  →    │
│ │book│ │book│ │book│        │
│ └────┘ └────┘ └────┘        │
├─────────────────────────────┤
│  🏠    🔍    ❤️              │
│ ホーム  検索  お気に入り      │
└─────────────────────────────┘
```

**棚の構成と表示ロジック**:

| 棚 | データソース | 表示条件 | 表示件数 |
|----|-------------|----------|----------|
| 続きから読む | Bookmark (SwiftData) | しおりが 1 件以上 | 最大 10 件 (lastReadAt 降順) |
| おすすめ著者 | ReadingHistory + BookReview → スコアリング | 常時表示 | 最大 10 件 |
| 最近のレビュー | BookReview (SwiftData) | レビューが 1 件以上 | 最大 10 件 (updatedAt 降順) |
| 作品タイプ別 | カタログ classification | 常時表示 | カテゴリ毎に最大 20 件 |
| 新着作品 | カタログ releaseDate | 常時表示 | 最大 20 件 |

**棚の表示順**:
1. 続きから読む（しおりあり時のみ）
2. おすすめ著者
3. 最近のレビュー（レビューあり時のみ）
4. 作品タイプ別（短編 → 長編 → エッセイ → 戯曲 → 児童文学 → 詩）
5. 新着作品

### S1-a: おすすめ著者ロジック（レビュー・閲覧履歴ベース）

**入力データ**:
- `ReadingHistory`: bookId, authorPersonId, classification, viewCount, lastViewedAt
- `BookReview`: bookId, authorName, rating, createdAt

**スコアリングアルゴリズム**:

```
AuthorScore = Σ(作品スコア) per author

作品スコア:
  - レビュー済み: rating × 3.0
  - 閲覧あり: min(viewCount, 5) × 1.0
  - 同分類ボーナス: 最頻閲覧分類と一致する場合 +2.0

最終スコア = AuthorScore × recencyDecay(lastInteractionDate)
recencyDecay = max(0.5, 1.0 − daysSinceLastInteraction / 90)
```

**フォールバック（コールドスタート）**:
- 閲覧履歴 + レビューが合計 3 件未満の場合
- カタログ内の作品数上位著者を表示（夏目漱石, 芥川龍之介, 太宰治 等）
- 表示ラベル:「人気の著者」に切り替え

**除外ルール**:
- 既に全作品を閲覧済みの著者はスコアを下げる（× 0.3）

### S4: 作品詳細

**あらすじ表示フロー**:
```
1. summaries.json から bookId で検索
   ├── ヒット → あらすじを表示
   └── ミス → 2 へ
2. SwiftData キャッシュ (GeneratedSummary) から検索
   ├── ヒット → キャッシュされたあらすじを表示
   └── ミス → 3 へ
3. LLM API であらすじ生成
   ├── 成功 → 表示 + SwiftData にキャッシュ保存
   └── 失敗 → 「あらすじはまだありません」を表示
```

**あらすじ生成の入力**:
- 本文冒頭 2,000 文字
- プロンプト: 「以下の日本文学作品の冒頭から、ネタバレを含まない 100〜200 文字のあらすじを生成してください」

### S5: 著者詳細

- 著者画像（Wikipedia API）
- 著者名（漢字 + ローマ字）
- 生没年
- 作品一覧（カタログから取得）
- 作品タップ → 作品詳細へ遷移

### S6: 読書画面

- **デフォルト**: 縦書きページめくり（WKWebView + CSS `writing-mode: vertical-rl`）
- **代替**: 横書きスクロール
- ページ位置インジケーター（現在ページ / 総ページ数）
- しおり自動保存（ページ遷移時）
- 読書開始時に ReadingHistory を記録 / 更新

### S8: レビュー投稿

- 星評価（1〜5、タップで選択）
- コメント（テキスト入力、任意）
- 保存 → BookReview に upsert
- 保存後、おすすめ著者スコアに即時反映

## 3. データモデル

### 既存モデル（変更なし）

| モデル | 種別 | 用途 |
|--------|------|------|
| Book | Struct (Codable) | カタログ作品データ |
| Person | Struct (Codable) | カタログ著者データ |
| FavoriteBook | SwiftData @Model | お気に入り |
| Bookmark | SwiftData @Model | 読書位置（しおり） |
| BookReview | SwiftData @Model | レビュー（星 + コメント） |
| ReadingSettings | @Observable | 読書設定 |

### 新規モデル

#### ReadingHistory（SwiftData @Model）
```swift
@Model
final class ReadingHistory {
    @Attribute(.unique) var bookId: Int
    var authorPersonId: Int
    var title: String
    var authorName: String
    var classification: String
    var viewCount: Int
    var lastViewedAt: Date
}
```

#### GeneratedSummary（SwiftData @Model）
```swift
@Model
final class GeneratedSummary {
    @Attribute(.unique) var bookId: Int
    var summary: String
    var generatedAt: Date
}
```

### 作品タイプ分類マッピング

```swift
enum WorkType: String, CaseIterable, Sendable {
    case shortStory = "短編"
    case novel = "長編"
    case essay = "エッセイ"
    case drama = "戯曲"
    case childrenLiterature = "児童文学"
    case poetry = "詩"
    case other = "その他"
}
```

分類ルール（`Book.classification` → `WorkType`）:
- NDC 分類コードまたはキーワードマッチでマッピング
- 「童話」「児童」→ `.childrenLiterature`
- 「詩」「詩歌」→ `.poetry`
- 未分類 → `.other`

## 4. 画面遷移

```
TabView
├── Tab 1: ホーム (HomeScreen)
│   ├── → AuthorDetailScreen (push)
│   │   └── → WorkDetailScreen (push)
│   ├── → WorkDetailScreen (push)
│   │   ├── → ReaderScreen (fullScreenCover)
│   │   ├── → AuthorDetailScreen (push)
│   │   └── → ReviewSheet (sheet)
│   └── → ReaderScreen (fullScreenCover)
│
├── Tab 2: 検索 (SearchScreen)
│   └── → WorkDetailScreen (push)
│       └── (同上)
│
└── Tab 3: お気に入り (FavoritesScreen)
    └── → WorkDetailScreen (push)
        └── (同上)
```

## 5. API / データアクセス

| 操作 | レイヤー | ソース |
|------|---------|--------|
| カタログ検索 | CatalogService (actor) | バンドル JSON |
| 本文取得 | TextFetchService (actor) | 青空文庫サーバー + ディスクキャッシュ |
| 著者画像取得 | AuthorDetailViewModel | Wikipedia REST API |
| あらすじ取得 | SummaryService (新規) | バンドル JSON → SwiftData キャッシュ → LLM API |
| おすすめ著者算出 | RecommendationService (新規) | SwiftData (ReadingHistory + BookReview) |
| 閲覧履歴記録 | ReadingHistoryService (新規) | SwiftData (ReadingHistory) |

## 6. エラーハンドリング

| シナリオ | 対応 |
|---------|------|
| オフラインでホーム表示 | キャッシュ済み棚データを表示、取得不可棚は非表示 |
| あらすじ生成失敗 | 「あらすじはまだありません」テキスト表示 |
| おすすめ著者算出で履歴不足 | フォールバック（作品数上位著者）に切り替え |
| 本文取得失敗 | エラーメッセージ + リトライボタン |
| Wikipedia API 失敗 | デフォルトアイコン表示 |
