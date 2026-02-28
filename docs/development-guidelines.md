# 開発ガイドライン: 青空文庫リーダー v2

## 1. 開発環境

| 項目 | バージョン |
|------|-----------|
| macOS | 15.0+ |
| Xcode | 16.0+ |
| iOS Deployment Target | 17.0 |
| Swift | 6.2 |
| Swift Concurrency | Strict (`SWIFT_STRICT_CONCURRENCY: complete`) |

### セットアップ手順

```bash
git clone https://github.com/inoue0124/aozora-reader-ios.git
cd aozora-reader-ios
brew install xcodegen mint
mint bootstrap          # SwiftLint / SwiftFormat インストール
xcodegen generate       # .xcodeproj 生成
open App.xcodeproj      # Xcode で開く
```

## 2. アーキテクチャ規約

### レイヤー構造

```
View → ViewModel → Service → Data
```

- 依存は上から下への一方向のみ
- 下位レイヤーは上位レイヤーを import しない
- 同レイヤー間の直接参照は避ける

### View Layer

```swift
// ✅ 正しい
struct HomeScreen: View {
    @State private var viewModel = HomeViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        // UI のみ
    }
}

// ❌ 誤り: View にビジネスロジック
struct HomeScreen: View {
    func calculateScore() -> Double { ... }  // Service に移動すべき
}
```

### ViewModel Layer

```swift
// ✅ 正しい
@Observable
@MainActor
final class HomeViewModel {
    var recommendedAuthors: [RecommendedAuthor] = []
    var isLoading = false

    func load(modelContext: ModelContext) async {
        isLoading = true
        recommendedAuthors = await RecommendationService.shared
            .recommendAuthors(context: modelContext)
        isLoading = false
    }
}

// ❌ 誤り: ObservableObject / @Published
class HomeViewModel: ObservableObject {
    @Published var authors: [Author] = []
}
```

### Service Layer

```swift
// ✅ 正しい: actor ベース
actor RecommendationService {
    static let shared = RecommendationService()
    func recommendAuthors(context: ModelContext) -> [RecommendedAuthor] { ... }
}

// ❌ 誤り: class + DispatchQueue
class RecommendationService {
    private let queue = DispatchQueue(label: "recommendation")
}
```

## 3. Swift 6.2 / Concurrency 規約

### 必須事項

- `Sendable` 準拠を徹底する（構造体は自動準拠、クラスは明示）
- `@MainActor` を UI 更新に関わるすべての ViewModel に適用する
- 構造化された並行性（`async let` / `TaskGroup`）を優先する
- `nonisolated` の明示的な使用でアクター境界を明確にする

### 禁止事項

| 非推奨 | 代替 |
|--------|------|
| `ObservableObject` / `@Published` | `@Observable` |
| `@StateObject` | `@State` |
| `@ObservedObject` | `@Bindable` |
| `@EnvironmentObject` | `@Environment` |
| `DispatchQueue` | `actor` / `Task` |
| `completion:` コールバック | `async/await` |

## 4. 命名規約

Swift API Design Guidelines に準拠する。

| 対象 | 規則 | 例 |
|------|------|-----|
| 型名 | UpperCamelCase | `ReadingHistory`, `WorkType` |
| メソッド / 変数 | lowerCamelCase | `recommendAuthors()`, `viewCount` |
| Boolean | is/has/can/should プレフィックス | `isLoading`, `hasReviews` |
| Protocol | -able/-ing サフィックス or 名詞 | `Sendable`, `ScoringStrategy` |
| enum case | lowerCamelCase | `.shortStory`, `.childrenLiterature` |
| ファイル名 | 主要型名と一致 | `ReadingHistory.swift` |

## 5. ファイル配置規約

```
Sources/
├── App/
│   ├── Models/      # データモデル（1 ファイル 1 型）
│   ├── Services/    # ビジネスロジック・データアクセス
│   └── Resources/   # バンドルリソース
└── Features/
    └── <FeatureName>/
        ├── ViewModel/  # @Observable ViewModel
        └── View/       # SwiftUI View
```

- 1 ファイル 1 型を原則とする
- Feature Module は `Features/<FeatureName>/` 配下に配置
- 共有コンポーネントは `App/` 配下の適切なディレクトリに配置

## 6. SwiftData 規約

- `@Model` は `Models/` ディレクトリに配置
- `@Attribute(.unique)` でユニーク制約を付与（bookId 等）
- リレーションは使わず、ID で参照（フラット構造）
- `ModelContext` は View の `@Environment` から ViewModel に渡す

```swift
// ✅ 正しい: View から ModelContext を渡す
struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()

    var body: some View {
        // ...
        .task { await viewModel.load(modelContext: modelContext) }
    }
}
```

## 7. Git ワークフロー

### ブランチ戦略

```
main                    # 安定ブランチ
feature/<issue>-<desc>  # 機能開発
fix/<issue>-<desc>      # バグ修正
```

### コミットメッセージ

Conventional Commits 形式:

```
<type>(<scope>): <subject>

type: feat | fix | docs | style | refactor | test | chore | build | ci | perf | revert
scope: home | reader | search | review | catalog | ...
```

例:
```
feat(home): add recommended authors shelf based on reading history
fix(reader): correct bookmark restore after font size change
docs(architecture): update recommendation service design
```

### PR ルール

- 1 PR = 1 機能 or 1 修正
- レビュー前にセルフチェック
- CI（ビルド + テスト）が通ること

## 8. ツール

| ツール | 用途 | 設定ファイル |
|--------|------|-------------|
| XcodeGen | `.xcodeproj` 生成 | `project.yml` |
| Mint | CLI ツール管理 | `Mintfile` |
| SwiftLint | リンター | `.swiftlint.yml` |
| SwiftFormat | フォーマッター | `.swiftformat` |
| Fastlane | ビルド・配信自動化 | `fastlane/` |

**注意**: `.xcodeproj` は直接編集しない。変更は `project.yml` に反映して `xcodegen generate` を実行する。

## 9. テスト方針

| 対象 | フレームワーク | 命名規則 |
|------|--------------|---------|
| Service ロジック | Swift Testing (`@Test`) | `test<メソッド名>_<条件>_<期待結果>` |
| ViewModel | Swift Testing (`@Test`) | 同上 |
| UI テスト | XCUITest | `test<画面名><操作>` |

優先的にテストすべき箇所:
1. `RecommendationService` のスコアリングロジック
2. `SummaryService` のフォールバック分岐
3. `WorkType` の分類マッピング
4. `ReadingHistoryService` の upsert 動作

## 10. パフォーマンス指針

- ホーム画面: 棚は LazyVStack + LazyHStack で遅延描画
- カタログ検索: 17,000 件でも体感遅延なし（actor 内インメモリ検索）
- 本文キャッシュ: ディスク + メモリの 2 層キャッシュ
- おすすめ著者: スコア計算は非同期、結果はメモリキャッシュ
- あらすじ生成: LLM API 呼び出しは非同期、SwiftData にキャッシュ
