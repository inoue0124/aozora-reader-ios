# ローカル実行手順 & 未解決 TODO

## ローカル実行手順

### 前提条件
- macOS + Xcode 16.0 以上
- iOS 17.0+ シミュレータ or 実機
- Homebrew（XcodeGen / Mint インストール用）

### セットアップ

```bash
# 1. リポジトリクローン
git clone https://github.com/inoue0124/aozora-reader-ios.git
cd aozora-reader-ios

# 2. ツールインストール（未インストールの場合）
brew install xcodegen mint

# 3. SwiftLint / SwiftFormat インストール（Mintfile で管理）
mint bootstrap

# 4. Xcode プロジェクト生成
xcodegen generate

# 5. iOS シミュレータランタイムがない場合
xcodebuild -downloadPlatform iOS

# 6. シミュレータ作成（必要に応じて）
xcrun simctl create "iPhone 16" \
  "com.apple.CoreSimulator.SimDeviceType.iPhone-16" \
  "com.apple.CoreSimulator.SimRuntime.iOS-26-2"

# 7. ビルド & 実行
open App.xcodeproj
# Xcode で Run (⌘R)
```

### XcodeBuildMCP でのビルド

```bash
# session defaults 設定
session_set_defaults {
  "projectPath": "<repo>/App.xcodeproj",
  "scheme": "App",
  "simulatorName": "iPhone 16"
}

# ビルド
build_sim       # ビルドのみ
build_run_sim   # ビルド & シミュレータ起動
test_sim        # テスト実行
```

### Lint / Format

```bash
mint run swiftlint lint Sources/     # Lint チェック
mint run swiftformat Sources/        # フォーマット
```

## 実装済み機能一覧

### v1 基盤機能（#12〜#22）

| # | 機能 | PR | 状態 |
|---|------|-----|------|
| 1 | API クライアント + 基本モデル（Book, Person, AozoraCatalog） | #12 | ✅ |
| 2 | 作品検索（タイトル/著者、検索モード切替） | #13 | ✅ |
| 3 | 作品詳細画面（メタデータ、著者リンク、図書カード） | #14 | ✅ |
| 4 | 著者詳細（Wikipedia 顔画像 + 作品一覧） | #15 | ✅ |
| 5 | 読書画面（HTML パース → AttributedString） | #16 | ✅ |
| 6 | 読書設定（フォント/行間/余白/テーマ/レイアウト） | #17 | ✅ |
| 7 | しおり（読書位置 ScrollView オフセット自動保存） | #18 | ✅ |
| 8 | お気に入り（SwiftData + @Query） | #19 | ✅ |
| 9 | オフライン読書（テキストファイルキャッシュ） | #20 | ✅ |
| 10 | AI 表紙生成（カラープレースホルダー） | #21 | ✅ |
| 11 | レビュー機能（星評価 + コメント、ローカル保存） | #22 | ✅ |

### v2 拡張機能（#24〜#36）

| # | 機能 | PR | 状態 |
|---|------|-----|------|
| 12 | 縦書きページめくりモード | #24 | ✅ |
| 13 | 縦書きデフォルト化 + ページ位置インジケータ | #26 | ✅ |
| 14 | ReadingHistory / WorkType / ReadingHistoryService | #33 | ✅ |
| 15 | RecommendationService（著者スコアリング） | #34 | ✅ |
| 16 | ホーム画面（棚 UI: 続きを読む / おすすめ著者 / レビュー / ジャンル別） | #35 | ✅ |
| 17 | 作品詳細あらすじ表示（固定JSON + SwiftDataキャッシュ + フォールバック） | #36 | ✅ |

## アーキテクチャ

```
Sources/
├── App/
│   ├── App.swift                       # @main + SwiftData container
│   ├── ContentView.swift               # TabView (ホーム + 検索 + お気に入り)
│   ├── Models/
│   │   ├── Book.swift                  # 作品モデル (Codable, Sendable)
│   │   ├── Person.swift                # 著者モデル (Codable, Sendable)
│   │   ├── AozoraCatalog.swift         # カタログコンテナ
│   │   ├── FavoriteBook.swift          # SwiftData: お気に入り
│   │   ├── Bookmark.swift              # SwiftData: しおり
│   │   ├── BookReview.swift            # SwiftData: レビュー
│   │   ├── ReadingHistory.swift        # SwiftData: 閲覧履歴
│   │   ├── GeneratedSummary.swift      # SwiftData: あらすじキャッシュ
│   │   ├── ReadingSettings.swift       # UserDefaults: 読書設定
│   │   └── WorkType.swift              # 作品分類 Enum (NDC マッピング)
│   ├── Services/
│   │   ├── CatalogService.swift        # ローカル検索 (actor)
│   │   ├── TextFetchService.swift      # テキスト取得 + キャッシュ (actor)
│   │   ├── AozoraTextParser.swift      # HTML → AttributedString
│   │   ├── CoverImageService.swift     # 表紙カラー生成 (actor)
│   │   ├── RecommendationService.swift # 著者レコメンド (@Observable @MainActor)
│   │   ├── ReadingHistoryService.swift # 閲覧履歴管理 (@Observable @MainActor)
│   │   └── SummaryService.swift        # あらすじ取得 (@Observable @MainActor)
│   └── Resources/
│       ├── aozora_catalog.json         # 青空文庫カタログ (17,716作品)
│       └── summaries.json              # 事前収録あらすじ (主要50作品)
└── Features/
    ├── Home/                           # ホーム画面（棚 UI）
    ├── Search/                         # 検索画面
    ├── WorkDetail/                     # 作品詳細画面 + あらすじ
    ├── AuthorDetail/                   # 著者詳細画面
    ├── Reader/                         # 読書画面 + 縦書きページめくり + 設定
    ├── Favorites/                      # お気に入り画面
    └── Review/                         # レビュー機能
```

### データ永続化

| ストレージ | 用途 | モデル |
|-----------|------|--------|
| SwiftData | ユーザーデータ | FavoriteBook, Bookmark, BookReview, ReadingHistory, GeneratedSummary |
| UserDefaults | 軽量設定 | ReadingSettings (テーマ, フォントサイズ, 行間, 余白, レイアウト) |
| Bundle JSON | 読み取り専用カタログ | aozora_catalog.json, summaries.json |
| ディスクキャッシュ | テキストファイル | ~/Library/Caches/AozoraTexts/{bookId}.txt |

### 並行性モデル

| コンポーネント | 分離方式 | 理由 |
|--------------|---------|------|
| ViewModel 全般 | @MainActor | UI 更新はメインスレッド必須 |
| CatalogService | actor | インメモリインデックスの共有アクセス |
| TextFetchService | actor | HTTP + ディスク I/O、キャッシュ協調 |
| CoverImageService | actor | ハッシュ計算のスレッドセーフ性 |
| RecommendationService | @MainActor | @Observable 状態の更新 |
| ReadingHistoryService | @MainActor | SwiftData 書き込みは MainActor 必須 |
| SummaryService | @MainActor | SwiftData + @Observable |

## 未解決 TODO

### 高優先度
- [ ] **青空文庫 API 復旧対応**: aozorahack API (pubserver2) がダウン中のため、バンドル CSV データで代替中。API が復旧したら動的取得に切り替え
- [ ] **カタログ更新機構**: 現在バンドル JSON 固定。定期的な更新、またはリモートからの差分取得が必要
- [ ] **Shift_JIS テキストの文字化け確認**: 一部作品で文字化けの可能性あり。複数作品での実地テストが必要
- [ ] **ルビ表示の改善**: 現在はカッコ表記（漢字（かんじ））。将来的にはルビ専用レイアウトを検討

### 中優先度
- [ ] **AI 表紙画像の実生成**: 現在はカラープレースホルダー。DALL-E 等の API キー設定後に実画像生成対応
- [ ] **著者画像の表示確認**: Wikipedia API で取得。著者名のマッチングが不完全な場合あり
- [ ] **しおり復元の精度**: ScrollView のオフセットベースのため、フォントサイズ変更後にずれる可能性
- [ ] **検索パフォーマンス**: 17,000 件の全件スキャン。大量データでの遅延が懸念される場合はインデックス構築を検討
- [ ] **エラーハンドリング強化**: ネットワークエラー時のリトライ UI が未実装
- [ ] **LLM あらすじ生成**: 現在は本文冒頭フォールバック。将来的に LLM API で高品質なあらすじを自動生成
- [ ] **レコメンドアルゴリズム改善**: 現在はスコアリングベース。協調フィルタリング等の導入を検討

### 低優先度
- [ ] **テスト追加**: ViewModel / Service のユニットテストが不足
- [ ] **アクセシビリティ**: VoiceOver 対応の検証
- [ ] **iPad / macOS 対応**: 現在 iPhone のみ
- [ ] **レビュー共有機能**: 現在ローカルのみ。将来的にサーバー同期
- [ ] **Bundle ID 変更**: `com.example.app` からプロダクション用に変更
- [ ] **アプリアイコン**: デフォルトアイコンのままのため、カスタムアイコンを作成

## データソース

- **カタログ**: 青空文庫公式 CSV (`list_person_all_extended_utf8.csv`) から JSON に変換してバンドル（17,716 作品）
- **あらすじ**: `summaries.json`（主要 50 作品を事前収録）+ 本文冒頭フォールバック
- **本文**: 青空文庫サーバー (`www.aozora.gr.jp`) から直接取得、ディスクキャッシュ
- **著者画像**: Wikipedia REST API (`ja.wikipedia.org/api/rest_v1/page/summary/`)
- **広告**: なし（設計方針として禁止）
