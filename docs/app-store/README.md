# ⌘IME の Mac App Store 提出

掲載する日本語・英語の説明、キーワード、審査メモ、価格の基準は [listing.json](listing.json) にあります。アプリ内のポリシーリンクは [privacy.md](privacy.md) の main 版を開きます。提出時に外部から読めることを確認します。

## ビルドと配布署名

1. App Store Connect で対象チームの `com.kazuki.cmdime` を照合します。初回のみ macOS のアプリレコードを作成し、既存ビルドの番号を確認します。契約・税金・口座の状態は同じチームの「ビジネス」で確認します。
2. `apps/cmd-ime-store` で `make test` を実行します。バージョンはリポジトリ直下の `manifest.toml` から読み取ります。
3. そのバージョンに使える新しいビルド番号を指定して `make archive-app-store BUILD_NUMBER=番号` を実行します。配布署名を利用できる環境で `make export-app-store BUILD_NUMBER=番号` を実行し、配布パッケージとアプリの署名を検証します。
4. 配布ビルドをAppleにアップロードし、App Store Connectで処理が終わった実ビルドのバージョンと番号を照合します。

## 掲載と審査

日本円の基準価格を300円の有料ダウンロードに設定します。掲載原稿、設定画面のスクリーンショット、プライバシー回答、年齢制限指定、暗号化の回答を登録します。「App Reviewに関する情報」の連絡先には組織が指定した実際の担当者を使います。

Mac上で左右のCommand単独タップによる入力切替、切替後に入力・確定した文字、Command-C/Vと入力監視の許可操作を確認します。バージョンに検証済みビルドを選び、「審査用に追加」から提出を確定します。「審査待ち」以降の状態と提出時刻をApp Store Connectで確認します。

[Appleの審査提出手順](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/)
