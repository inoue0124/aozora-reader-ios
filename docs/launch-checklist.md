# ローカル実行手順 & 未解決 TODO

## ローカル実行手順

### 前提条件
- macOS + Xcode 16.0 以上
- iOS 17.0+ シミュレータ or 実機

### セットアップ

```bash
# 1. リポジトリクローン
git clone https://github.com/inoue0124/aozora-reader-ios.git
cd aozora-reader-ios

# 2. XcodeGen インストール（未インストールの場合）
brew install xcodegen

# 3. Xcode プロジェクト生成
xcodegen generate

# 4. iOS シミュレータランタイムがない場合
xcodebuild -downloadPlatform iOS

# 5. シミュレータ作成（必要に応じて）
xcrun simctl create "iPhone 16" \
  "com.apple.CoreSimulator.SimDeviceType.iPhone-16" \
  "com.apple.CoreSimulator.SimRuntime.iOS-26-2"

# 6. ビルド & 実行
open App.xcodeproj
# Xcode で Run (⌘R)
```

### XcodeBuildMCP でのビルド

```bash
# session defaults 設定後
build_sim  # ビルドのみ
build_run_sim  # ビルド & シミュレータ起動
```

## 実装済み機能一覧

| # | 機能 | PR | 状態 |
|---|------|-----|------|
| 1 | API クライアント + 基本モデル | #12 | ✅ |
| 2 | 作品検索（タイトル/著者） | #13 | ✅ |
| 3 | 作品詳細画面 | #14 | ✅ |
| 4 | 著者詳細（顔画像 + 出典） | #15 | ✅ |
| 5 | 読書画面（HTML パース） | #16 | ✅ |
| 6 | 読書設定（フォント/行間/余白/テーマ） | #17 | ✅ |
| 7 | しおり（読書位置自動保存） | #18 | ✅ |
| 8 | お気に入り | #19 | ✅ |
| 9 | オフライン読書（ファイルキャッシュ） | #20 | ✅ |
| 10 | AI 表紙生成（プレースホルダー） | #21 | ✅ |
| 11 | レビュー機能（ローカル保存） | #22 | ✅ |

## アーキテクチャ

```
Sources/
├── App/
│   ├── App.swift                    # @main + SwiftData container
│   ├── ContentView.swift            # TabView (検索 + お気に入り)
│   ├── Models/
│   │   ├── Book.swift               # 作品モデル (Codable)
│   │   ├── Person.swift             # 著者モデル (Codable)
│   │   ├── AozoraCatalog.swift      # カタログ全体
│   │   ├── FavoriteBook.swift       # SwiftData: お気に入り
│   │   ├── Bookmark.swift           # SwiftData: しおり
│   │   ├── BookReview.swift         # SwiftData: レビュー
│   │   └── ReadingSettings.swift    # UserDefaults: 読書設定
│   ├── Services/
│   │   ├── CatalogService.swift     # ローカル検索 (actor)
│   │   ├── TextFetchService.swift   # テキスト取得 + キャッシュ (actor)
│   │   ├── AozoraTextParser.swift   # HTML → AttributedString
│   │   └── CoverImageService.swift  # 表紙画像サービス
│   └── Resources/
│       └── aozora_catalog.json      # 青空文庫カタログ (17,716作品)
└── Features/
    ├── Search/                      # 検索画面
    ├── WorkDetail/                  # 作品詳細画面
    ├── AuthorDetail/                # 著者詳細画面
    ├── Reader/                      # 読書画面 + 設定
    ├── Favorites/                   # お気に入り画面
    └── Review/                      # レビュー機能
```

## 未解決 TODO

### 高優先度
- [ ] **青空文庫 API 復旧対応**: aozorahack API (pubserver2) がダウン中のため、バンドルCSVデータで代替中。API が復旧したら動的取得に切り替えること
- [ ] **カタログ更新機構**: 現在バンドルJSON固定。定期的な更新、またはリモートからの差分取得が必要
- [ ] **Shift_JIS テキストの文字化け確認**: 一部作品で文字化けの可能性あり。複数作品での実地テストが必要
- [ ] **ルビ表示の改善**: 現在はカッコ表記（漢字（かんじ））。将来的にはルビ専用レイアウトを検討

### 中優先度
- [ ] **AI 表紙画像の実生成**: 現在はカラープレースホルダー。DALL-E 等の API キー設定後に実画像生成対応
- [ ] **著者画像の表示確認**: Wikipedia API で取得。著者名のマッチングが不完全な場合あり
- [ ] **しおり復元の精度**: ScrollView のオフセットベースのため、フォントサイズ変更後にずれる可能性
- [ ] **検索パフォーマンス**: 17,000件の全件スキャン。大量データでの遅延が懸念される場合はインデックス構築を検討
- [ ] **エラーハンドリング強化**: ネットワークエラー時のリトライ UI が未実装

### 低優先度
- [ ] **テスト追加**: ViewModel / Service のユニットテストが不足
- [ ] **アクセシビリティ**: VoiceOver 対応の検証
- [ ] **iPad / macOS 対応**: 現在 iPhone のみ
- [ ] **レビュー共有機能**: 現在ローカルのみ。将来的にサーバー同期
- [ ] **Bundle ID 変更**: `com.example.app` からプロダクション用に変更
- [ ] **アプリアイコン**: デフォルトアイコンのままのため、カスタムアイコンを作成

## データソース

- **カタログ**: 青空文庫公式 CSV (`list_person_all_extended_utf8.csv`) から JSON に変換してバンドル
- **本文**: 青空文庫サーバー (`www.aozora.gr.jp`) から直接取得、ディスクキャッシュ
- **著者画像**: Wikipedia REST API (`ja.wikipedia.org/api/rest_v1/page/summary/`)
- **広告**: なし（設計方針として禁止）
