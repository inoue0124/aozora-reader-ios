fastlane ドキュメント
----

# インストール

Xcode コマンドラインツールの最新版がインストールされていることを確認してください:

```sh
xcode-select --install
```

fastlane のインストール手順は [Installing fastlane](https://docs.fastlane.tools/#installing-fastlane) を参照してください。

# 利用可能なアクション

## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

アプリをビルドする（Debug / iOS Simulator）

### ios test

```sh
[bundle exec] fastlane ios test
```

ユニットテストを実行する（iPhone 16 シミュレータ）

### ios beta

```sh
[bundle exec] fastlane ios beta
```

ビルド番号をインクリメントし、アーカイブして TestFlight にアップロードする

----

この README.md は [fastlane](https://fastlane.tools) の実行時に自動生成されます。

詳細は [docs.fastlane.tools](https://docs.fastlane.tools) を参照してください。
