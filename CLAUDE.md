# CLAUDE.md

このプロジェクトは iOS Agent Dev Template で生成された SwiftUI + MVVM アプリケーションです。

## アーキテクチャ

- **SwiftUI + MVVM** を採用
- View → ViewModel → Repository → Model のレイヤー構造
- レイヤー間の依存は上から下への一方向のみ許可

## Swift バージョン

- Swift 6.2 / SwiftUI を前提とする
- Observation フレームワーク（`@Observable`）を使用する。`ObservableObject` / `@Published` は非推奨
- Swift Concurrency（`async/await`, `Sendable`, actor 分離）に準拠する
- 旧 API（`@StateObject`, `@ObservedObject`, `@EnvironmentObject`）は使用しない。`@State`, `@Bindable`, `@Environment` を使う

## ディレクトリ構成

- `Sources/App/` — アプリエントリポイント
- `Sources/Features/<FeatureName>/` — Feature Module（View / ViewModel / Model / Repository）
- `Tests/` — テスト

## コーディング規約

- 命名: Swift API Design Guidelines に準拠
- SwiftLint / SwiftFormat の設定に従う（Mint で管理）
- ファイル1つにつき1型を基本とする

## ツール

- XcodeGen: `project.yml` からプロジェクトを生成。`.xcodeproj` は直接編集しない
- Mint: SwiftLint / SwiftFormat のバージョン管理
- Fastlane: ビルド・テスト・配信の自動化

## ブランチ戦略

- main: 安定ブランチ
- feature/<issue-number>-<description>: 機能開発

## コミットメッセージ

Conventional Commits に準拠:

```
<type>(<scope>): <subject>

type: feat, fix, docs, style, refactor, test, chore, build, ci, perf, revert
```

## MCP サーバー

利用可能な場合は MCP ツールを優先して使用する:

- XcodeBuildMCP: ビルド・テスト実行・シミュレータ操作
- xcodeproj-mcp-server: プロジェクトファイル操作
