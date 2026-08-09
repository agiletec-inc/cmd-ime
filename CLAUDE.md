# CmdIME

左右Command keyなどをIME入力へ割り当てるnative macOS menu bar app。version正本は`manifest.toml`。
build/test/release commandはpackage manifest、Makefile、workflowから読む。

## 推測できない境界

- CGEvent hot pathは`shortcutList`、`exclusionAppsDict`等のglobal cacheを読む。設定の正本は
  `@MainActor AppSettings.shared`で、cacheは設定変更時に同期する。hot pathからUserDefaultsを読まない。
- keyCode `999`はswallow、`1000+`はmedia key。54/55は左右Command、102/104は英数/かな。意味を通常keyへ
  正規化しない。
- macOSはinput source変更等でevent tapを無効化する。heartbeat、Accessibility付与後retry、brew upgrade時の
  bundle置換監視を維持する。
- release appcastの配信正本はGitHub Release asset (`releases/latest/download/appcast.xml`)。既存クライアント移行中は
  同じ累積feedを`appcast` branchへdual-publishし、branch writerはIssue #137の測定可能な完了条件まで削除しない。
- native appなのでDockerを使わない。release signing/notarizationとlocal ad-hoc buildを混同しない。
- ユーザー向け文字列は必ず`L(_:)`(Sources/CmdIMESwift/Localization.swift)経由。`swift build`/`swift test`は
  `Localizable.xcstrings`をコンパイルしない(Xcode専用機能)ため、`Sources/CmdIMESwift/Resources/<locale>.lproj/
  Localizable.strings`を`xcstringstool compile`で事前コンパイルして正本と一緒にcommitする。文字列を追加・変更したら
  `xcrun xcstringstool compile Sources/CmdIMESwift/Resources/Localizable.xcstrings --output-directory
  Sources/CmdIMESwift/Resources --serialization-format text`で再生成し、`LocalizationCatalogTests`のdriftチェックを
  green にしてからcommitする。`scripts/package.sh`はSPMの`<Package>_<Target>.bundle`を`Contents/Resources/`へ
  手動でdittoする一文が要る — 標準の`swift build -c release`だけでは.appにリソースが同梱されない。

変更後はSwift test、build、必要ならevent tap/Accessibilityの実機確認を行う。コメントは周囲の密度と言語へ合わせる。
