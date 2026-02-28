# 用語集: 青空文庫リーダー v2

## ドメイン用語

| 用語 | 英語表記 | 定義 |
|------|---------|------|
| 青空文庫 | Aozora Bunko | 著作権が消滅した日本文学作品を無料で公開する電子図書館 |
| 作品 | Book / Work | 青空文庫に収録された文学作品。カタログ内の 1 エントリ |
| 著者 | Person / Author | 作品の著者。カタログでは Person として管理 |
| カタログ | Catalog | 青空文庫全作品のメタデータ一覧。バンドル JSON として同梱 |
| 棚 | Shelf / Rail | ホーム画面の横スクロールコンテンツ列。レール UI とも呼ぶ |
| しおり | Bookmark | 読書位置の保存。自動保存され、再開時に同位置へ復帰 |
| ルビ | Ruby | 漢字の読み仮名。青空文庫テキストでは `｜漢字《かんじ》` 形式 |
| 注記 | Annotation | 青空文庫テキスト内の書式指定。`［＃太字］` 等 |
| カード URL | Card URL | 青空文庫の作品紹介ページ URL |

## 作品タイプ

| 用語 | WorkType enum | 定義 |
|------|--------------|------|
| 短編 | `.shortStory` | 短編小説 |
| 長編 | `.novel` | 長編小説 |
| エッセイ | `.essay` | 随筆・随想 |
| 戯曲 | `.drama` | 戯曲・脚本 |
| 児童文学 | `.childrenLiterature` | 童話・児童向け文学作品 |
| 詩 | `.poetry` | 詩・詩歌 |
| その他 | `.other` | 上記に分類できない作品 |

## 機能用語

| 用語 | 英語表記 | 定義 |
|------|---------|------|
| おすすめ著者 | Recommended Authors | レビュー・閲覧履歴に基づきスコアリングで選定された著者一覧 |
| 閲覧履歴 | Reading History | ユーザーが作品を開いた記録。bookId・viewCount・lastViewedAt を保持 |
| スコアリング | Scoring | おすすめ著者を決定するための点数算出ロジック |
| recencyDecay | Recency Decay | スコアの時間減衰。最終閲覧日が古いほどスコアを減衰させる |
| コールドスタート | Cold Start | 閲覧履歴・レビューが少なく、パーソナライズが機能しない初期状態 |
| フォールバック | Fallback | コールドスタート時に作品数上位の著者を代わりに表示する挙動 |
| あらすじ | Summary | 作品の概要テキスト。固定 JSON または LLM 生成で提供 |
| 固定あらすじ | Bundled Summary | `summaries.json` に事前収録されたあらすじデータ |
| 生成補完 | Generated Summary | 固定あらすじに該当がない場合に LLM API で生成したあらすじ |
| 続きから読む | Continue Reading | しおりが保存されている作品への復帰導線 |
| レビュー | Review | ユーザーが作品に付ける星評価（1〜5）+ コメント |

## 技術用語

| 用語 | 定義 |
|------|------|
| SwiftData | Apple の永続化フレームワーク。`@Model` で宣言的にモデルを定義 |
| ModelContainer | SwiftData のデータベースコンテナ。App で一度だけ初期化 |
| ModelContext | SwiftData の操作コンテキスト。CRUD 操作の実行単位 |
| @Observable | Observation フレームワークのマクロ。ViewModel に適用 |
| @MainActor | メインスレッドでの実行を保証するアクター分離マーカー |
| actor | Swift Concurrency のスレッドセーフな参照型。Service 層で使用 |
| Sendable | アクター境界を越えて安全に転送可能な型であることを示すプロトコル |
| WKWebView | WebKit のビューコンポーネント。縦書きレンダリングに使用 |
| writing-mode: vertical-rl | CSS プロパティ。縦書き・右から左への文字方向 |
| XcodeGen | `project.yml` から `.xcodeproj` を生成するツール |
| Mint | Swift 製 CLI ツールのバージョン管理・実行ツール |
| Conventional Commits | コミットメッセージの構造化規約（`type(scope): subject`） |

## 略語

| 略語 | 正式名称 | 説明 |
|------|---------|------|
| PRD | Product Requirements Document | プロダクト要求定義書 |
| MVP | Minimum Viable Product | 最小実行可能プロダクト |
| MVVM | Model-View-ViewModel | UI アーキテクチャパターン |
| DTO | Data Transfer Object | レイヤー間データ転送用の構造体 |
| NDC | Nippon Decimal Classification | 日本十進分類法。作品分類に使用 |
| LLM | Large Language Model | 大規模言語モデル。あらすじ生成補完に使用 |
| API | Application Programming Interface | 外部サービスとの通信インターフェース |
