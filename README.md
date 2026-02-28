# iOS Agent Dev Template

iOS アプリ開発を Claude Code（AI エージェント）と共に進めるためのスターターテンプレート。

このリポジトリをクローンしてセットアップスクリプトを実行するだけで、iOS + AI エージェント開発をすぐに始められる環境が整います。

## 概要

このテンプレートは以下を提供します。

- **ビルド可能な SwiftUI + MVVM のベースアプリ** — サンプル Feature Module 付きで、セットアップ直後にビルド・実行できる
- **iOS 開発ツールの自動セットアップ** — XcodeGen、SwiftLint、SwiftFormat、Fastlane、Mint、gh CLI を一括インストール
- **[ios-claude-plugins](https://github.com/inoue0124/ios-claude-plugins) の導入** — アーキテクチャガード、コード品質チェック、テスト生成、コードレビュー支援、スペック駆動実装など iOS チーム開発を包括サポートするプラグイン群
- **MCP サーバーの設定** — XcodeBuildMCP / xcodeproj-mcp-server でビルド・テスト・プロジェクト操作を AI エージェントから直接実行可能に
- **チーム開発の基盤** — GitHub テンプレート、CI ワークフロー、pre-commit hook、コーディング規約設定

## クイックスタート

### 事前に必要なもの

以下は setup.sh では自動インストールされません。事前にインストールしてください。

| ツール | インストール方法 |
|---|---|
| macOS | — |
| Xcode | App Store からインストール |
| Homebrew | https://brew.sh |
| Claude Code | `npm install -g @anthropic-ai/claude-code`（[公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)） |

### セットアップ手順

```bash
# 1. テンプレートをクローン
git clone https://github.com/inoue0124/ios-agent-dev-template.git <your-project-name>
cd <your-project-name>

# 2. セットアップスクリプトを実行（ツールインストール・プロジェクト生成）
./scripts/setup.sh

# 3. Xcode でプロジェクトを開く
open *.xcodeproj

# 4. AI エージェントと開発スタート
claude
```

## セットアップスクリプトが行うこと

`scripts/setup.sh` は以下を順に実行します。

1. **前提条件の確認** — Xcode / Command Line Tools / Homebrew
2. **開発ツールのインストール**（未インストールのもののみ）
   - XcodeGen（project.yml から .xcodeproj を生成）
   - Mint（Swift 製 CLI ツールのバージョン管理）
   - SwiftLint / SwiftFormat（Mint 経由）
   - Fastlane（CI/CD 自動化・証明書管理・配信）
   - gh CLI（GitHub CLI）
3. **MCP サーバーの自動セットアップ**
   - Node.js / Docker を自動インストール
   - `.mcp.json` に XcodeBuildMCP / xcodeproj-mcp-server を設定
4. **ios-claude-plugins のインストール**
   - マーケットプレース登録 + 全10プラグインを自動インストール
5. **プロジェクト生成**
   - XcodeGen で project.yml から .xcodeproj を生成
   - SPM パッケージの解決
6. **Git hooks のインストール** — pre-commit / commit-msg

## セットアップ後の開発ワークフロー

セットアップ完了後、`claude` コマンドで AI エージェントと対話しながら開発を進められます。

### 作るものがまだ決まっていない場合 — スペック駆動開発

アイデアはあるが詳細が固まっていない段階では、スペック駆動開発スキルを使ってドキュメントから先に作成します。

```
1. docs/ideas/ にアイデアメモを置く（箇条書き・雑なメモでOK）
2. /prd-writing でプロダクト要求定義書を作成（ユーザー承認あり）
   ↓ 承認後、以下は自動で連鎖生成
3. /functional-design で機能設計書を作成
4. /architecture-design でアーキテクチャ設計書を作成
5. /repository-structure でリポジトリ構造定義書を作成
6. /development-guidelines で開発ガイドラインを作成
7. /glossary-gen で用語集を作成
```

生成されたドキュメントは `docs/` 配下に配置されます。

```
docs/
├── ideas/                      # 入力: アイデアメモ
├── product-requirements.md     # Step 1: プロダクト要求定義書
├── functional-design.md        # Step 2: 機能設計書
├── architecture.md             # Step 3: アーキテクチャ設計書
├── repository-structure.md     # Step 4: リポジトリ構造定義書
├── development-guidelines.md   # Step 5: 開発ガイドライン
├── glossary.md                 # Step 6: 用語集
└── features/                   # フィーチャー単位の実装スペック
```

ドキュメントが揃ったら、`/implement-feature` でフィーチャー単位の実装に進みます。

### 作るものが決まっている場合 — フィーチャー実装

`/implement-feature` で要件定義から実装までをスペック駆動で一気通貫に進められます。

```
1. /implement-feature で実装ワークフローを開始
   ↓ 要件定義書の生成（requirements-gen）— 機能要件・非機能要件・受け入れ条件を整理
   ↓ 詳細設計書の生成（design-gen）— MVVM 設計・モジュール構成・API 設計
   ↓ タスクリストの生成（task-gen）— 詳細設計から実装タスクを分解
2. 各タスクを順に実装
   ↓ アーキテクチャガード（ios-architecture）が MVVM 準拠を自動チェック
   ↓ コード品質チェック（swift-code-quality）が lint / format を実行
   ↓ テスト生成（swift-testing）がユニットテストを自動生成
3. コミット時に pre-commit hook が最終チェック
4. PR 作成時にレビュー支援（code-review-assist）が差分を分析
```

### 日常の開発でよく使うコマンド

| やりたいこと | Claude への指示例 |
|---|---|
| 新機能をスペック駆動で実装 | `/implement-feature` |
| Feature Module の雛形を生成 | `/new-feature` |
| テストを書く | 「LoginViewModel のユニットテストを生成して」 |
| コード品質チェック | `/quality-check` |
| コードレビュー | `/pr-review` |
| PR を作成 | `/pr-create` |
| Issue を作成 | `/issue-create` |
| アーキテクチャ監査 | `/arch-audit` |
| 規約チェック | `/convention-check` |
| 新メンバー向けガイド生成 | `/onboard` |

## ディレクトリ構成

```
<your-project-name>/
├── Sources/
│   ├── App/
│   │   ├── App.swift                  # SwiftUI エントリポイント
│   │   ├── ContentView.swift          # 初期画面
│   │   └── Info.plist
│   └── Features/
│       └── Sample/                    # MVVM サンプル Feature Module
│           ├── View/
│           ├── ViewModel/
│           ├── Model/
│           └── Repository/
├── Tests/
│   └── SampleFeatureTests/
├── scripts/
│   ├── setup.sh                       # 初回セットアップ
│   ├── clean.sh                       # キャッシュクリア
│   ├── bootstrap.sh                   # 依存解決・プロジェクト再生成
│   ├── lint.sh                        # SwiftFormat + SwiftLint 一括実行
│   └── hooks/
│       ├── pre-commit                 # コミット前の自動 lint
│       └── commit-msg                 # Conventional Commits チェック
├── fastlane/
│   ├── Fastfile                       # レーン定義（build, test, beta）
│   └── Appfile                        # App ID / Apple ID 設定
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── task.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── workflows/
│   │   └── ci.yml                     # PR 時の自動ビルド・テスト・lint
│   └── dependabot.yml                 # SPM 依存の自動アップデート
├── project.yml                        # XcodeGen プロジェクト定義
├── Mintfile                           # SwiftLint / SwiftFormat バージョン固定
├── CLAUDE.md                          # AI エージェントへの指示書
├── .swiftlint.yml
├── .swiftformat
├── .editorconfig
└── .gitignore
```

> サンプル Feature Module（`Sources/Features/Sample/`）は MVVM パターンの実装例です。新機能追加時の参考にしてください。

## ユーティリティスクリプト

`scripts/` ディレクトリに開発中に使うユーティリティスクリプトを用意しています。

| スクリプト | 用途 | 実行タイミング |
|---|---|---|
| `scripts/setup.sh` | 初回環境セットアップ | リポジトリクローン直後 |
| `scripts/clean.sh` | キャッシュクリア + プロジェクト再生成 | ビルドがおかしい時 |
| `scripts/bootstrap.sh` | Mint bootstrap → XcodeGen → SPM resolve | ブランチ切替後・依存更新時 |
| `scripts/lint.sh` | SwiftFormat + SwiftLint 一括実行 | コミット前・CI |

### scripts/clean.sh の対象

- `~/Library/Developer/Xcode/DerivedData` — ビルドキャッシュ
- `.build/` — SPM ローカルキャッシュ
- `~/Library/Caches/org.swift.swiftpm` — SPM グローバルキャッシュ
- `Package.resolved` の削除 + 再解決
- `.xcodeproj` の再生成（XcodeGen）

## 導入されるプラグイン

[ios-claude-plugins](https://github.com/inoue0124/ios-claude-plugins) から以下のプラグインが導入されます。

### Tier 1: 日常の開発サイクルで毎日使うもの

| プラグイン | 説明 |
|---|---|
| ios-architecture | MVVM 構造チェック・レイヤー依存検査・DI 提案 |
| team-conventions | コーディング規約・命名規則の自動検査・強制 |
| swift-code-quality | SwiftLint / SwiftFormat による静的解析・構文チェック |
| swift-testing | テスト生成・実行・カバレッジ分析 |
| github-workflow | 構造化 Issue 作成・差分解析 PR 作成 |
| code-review-assist | PR 差分分析・レビューコメント生成・影響範囲特定 |

### Tier 2: プロジェクト構築・配信フェーズで使うもの

| プラグイン | 説明 |
|---|---|
| ios-onboarding | プロジェクト構造解説・用語集生成・変更要約 |
| feature-module-gen | SwiftUI + MVVM Feature Module 雛形一式生成 |
| ios-distribution | アーカイブビルド・TestFlight アップロード自動化 |
| feature-implementation | 要件定義・詳細設計・タスクリストによるスペック駆動フィーチャー実装 |

## Git hooks

| フック | 内容 |
|---|---|
| `pre-commit` | SwiftFormat + SwiftLint を自動実行（`scripts/lint.sh` を呼び出し） |
| `commit-msg` | コミットメッセージのフォーマットチェック（Conventional Commits） |

> **ios-claude-plugins との役割分担について**
>
> ios-claude-plugins の `swift-code-quality` プラグインも SwiftLint / SwiftFormat を実行しますが、それは **Claude がコード編集中に品質を担保する**ためのものです。一方、pre-commit hook は **人間が手動でコミットする際のセーフティネット**として機能します。同じツールを使いますが実行タイミングと目的が異なるため、両方を併用する設計としています。

## ライセンス

MIT
