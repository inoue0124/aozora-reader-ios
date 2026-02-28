# リポジトリ構造: 青空文庫リーダー v2

## ディレクトリツリー

```
aozora-reader-ios/
├── CLAUDE.md                          # AI エージェント向けプロジェクト指示
├── project.yml                        # XcodeGen プロジェクト定義
├── Mintfile                           # SwiftLint / SwiftFormat バージョン管理
├── .swiftlint.yml                     # SwiftLint 設定
├── .swiftformat                       # SwiftFormat 設定
├── fastlane/                          # Fastlane 設定
│
├── docs/                              # プロジェクトドキュメント
│   ├── product-requirements.md        # プロダクト要求定義書
│   ├── functional-design.md           # 機能設計書
│   ├── architecture.md                # アーキテクチャ設計書
│   ├── repository-structure.md        # リポジトリ構造（本ファイル）
│   ├── development-guidelines.md      # 開発ガイドライン
│   ├── glossary.md                    # 用語集
│   ├── launch-checklist.md            # ローカル実行手順 & TODO
│   ├── ideas/                         # アイデアメモ
│   └── features/                      # Feature 別仕様（将来用）
│
├── Sources/
│   ├── App/                           # アプリエントリポイント
│   │   ├── App.swift                  # @main + SwiftData ModelContainer
│   │   ├── ContentView.swift          # TabView (ホーム / 検索 / お気に入り)
│   │   │
│   │   ├── Models/                    # データモデル
│   │   │   ├── AozoraCatalog.swift    # カタログルート (Codable, Sendable)
│   │   │   ├── Book.swift             # 作品モデル (Codable, Sendable)
│   │   │   ├── Person.swift           # 著者モデル (Codable, Sendable)
│   │   │   ├── FavoriteBook.swift     # SwiftData: お気に入り
│   │   │   ├── Bookmark.swift         # SwiftData: しおり（読書位置）
│   │   │   ├── BookReview.swift       # SwiftData: レビュー
│   │   │   ├── ReadingHistory.swift   # SwiftData: 閲覧履歴 ← 新規
│   │   │   ├── GeneratedSummary.swift # SwiftData: 生成あらすじキャッシュ ← 新規
│   │   │   ├── WorkType.swift         # 作品タイプ enum ← 新規
│   │   │   ├── RecommendedAuthor.swift # おすすめ著者 DTO ← 新規
│   │   │   └── ReadingSettings.swift  # @Observable: 読書設定
│   │   │
│   │   ├── Services/                  # ビジネスロジック・データアクセス
│   │   │   ├── CatalogService.swift           # カタログ検索 (actor)
│   │   │   ├── TextFetchService.swift         # テキスト取得 + キャッシュ (actor)
│   │   │   ├── AozoraTextParser.swift         # HTML → テキスト変換
│   │   │   ├── CoverImageService.swift        # 表紙カラー生成 (actor)
│   │   │   ├── RecommendationService.swift    # おすすめ著者スコアリング (actor) ← 新規
│   │   │   ├── SummaryService.swift           # あらすじ取得・生成補完 (actor) ← 新規
│   │   │   └── ReadingHistoryService.swift    # 閲覧履歴記録 (actor) ← 新規
│   │   │
│   │   ├── Resources/
│   │   │   ├── aozora_catalog.json    # 青空文庫カタログ (17,716 作品)
│   │   │   └── summaries.json         # 固定あらすじデータ ← 新規
│   │   │
│   │   ├── Assets.xcassets/           # アセットカタログ
│   │   └── Info.plist
│   │
│   └── Features/                      # Feature Module
│       ├── Home/                      # ホーム（発見画面） ← 新規
│       │   ├── ViewModel/
│       │   │   └── HomeViewModel.swift
│       │   └── View/
│       │       ├── HomeScreen.swift
│       │       ├── ShelfSectionView.swift     # 汎用棚コンポーネント
│       │       ├── AuthorCardView.swift       # おすすめ著者カード
│       │       ├── ReviewCardView.swift       # 最近のレビューカード
│       │       ├── ContinueReadingCardView.swift  # 続きから読むカード
│       │       └── WorkTypeShelfView.swift    # 作品タイプ別棚
│       │
│       ├── Search/                    # 検索画面
│       │   ├── ViewModel/
│       │   │   └── SearchViewModel.swift
│       │   └── View/
│       │       ├── SearchScreen.swift
│       │       ├── BookCoverView.swift
│       │       └── BookRowView.swift
│       │
│       ├── WorkDetail/                # 作品詳細画面
│       │   ├── ViewModel/
│       │   │   └── WorkDetailViewModel.swift
│       │   └── View/
│       │       └── WorkDetailScreen.swift
│       │
│       ├── AuthorDetail/              # 著者詳細画面
│       │   ├── ViewModel/
│       │   │   └── AuthorDetailViewModel.swift
│       │   └── View/
│       │       └── AuthorDetailScreen.swift
│       │
│       ├── Reader/                    # 読書画面
│       │   ├── ViewModel/
│       │   │   └── ReaderViewModel.swift
│       │   └── View/
│       │       ├── ReaderScreen.swift
│       │       ├── VerticalPagedReaderView.swift
│       │       └── ReadingSettingsSheet.swift
│       │
│       ├── Favorites/                 # お気に入り画面
│       │   ├── ViewModel/
│       │   │   └── FavoritesViewModel.swift
│       │   └── View/
│       │       └── FavoritesScreen.swift
│       │
│       └── Review/                    # レビュー機能
│           ├── ViewModel/
│           │   └── ReviewViewModel.swift
│           └── View/
│               ├── ReviewSheet.swift
│               └── StarRatingView.swift
│
├── Tests/                             # テスト
│   ├── Services/
│   │   ├── RecommendationServiceTests.swift   # ← 新規
│   │   ├── SummaryServiceTests.swift          # ← 新規
│   │   └── ReadingHistoryServiceTests.swift   # ← 新規
│   └── Models/
│       └── WorkTypeTests.swift                # ← 新規
│
└── App.xcodeproj/                     # XcodeGen 生成（手動編集しない）
```

## 新規ファイル一覧

| ファイル | 種別 | 概要 |
|---------|------|------|
| `Models/ReadingHistory.swift` | SwiftData @Model | 閲覧履歴（bookId, authorPersonId, viewCount, lastViewedAt） |
| `Models/GeneratedSummary.swift` | SwiftData @Model | LLM 生成あらすじのキャッシュ |
| `Models/WorkType.swift` | enum | 作品タイプ分類（短編/長編/エッセイ/戯曲/児童文学/詩/その他） |
| `Models/RecommendedAuthor.swift` | Struct (Sendable) | おすすめ著者の DTO |
| `Services/RecommendationService.swift` | actor | 閲覧履歴・レビューベースのおすすめ著者スコアリング |
| `Services/SummaryService.swift` | actor | あらすじ取得（固定JSON → キャッシュ → LLM生成） |
| `Services/ReadingHistoryService.swift` | actor | 閲覧履歴の記録・更新 |
| `Resources/summaries.json` | JSON | 主要作品の固定あらすじデータ |
| `Features/Home/**` | Feature Module | ホーム画面（棚 UI・おすすめ著者・レビュー棚等） |
| `Tests/Services/*Tests.swift` | テスト | 新規 Service のユニットテスト |
| `Tests/Models/WorkTypeTests.swift` | テスト | 作品タイプ分類のマッピングテスト |

## 既存ファイルの変更が必要なもの

| ファイル | 変更内容 |
|---------|---------|
| `App.swift` | ModelContainer に `ReadingHistory`, `GeneratedSummary` を追加 |
| `ContentView.swift` | TabView にホームタブを追加（3 タブ構成へ） |
| `ReaderViewModel.swift` | 読書開始時に ReadingHistoryService を呼び出し |
| `WorkDetailViewModel.swift` | SummaryService からあらすじ取得ロジックを追加 |
| `WorkDetailScreen.swift` | あらすじ表示セクションを追加 |
| `project.yml` | ソースパス変更があれば更新（通常不要） |
