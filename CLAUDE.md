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
- release appcastは専用`appcast` branchが配信正本。mainの`appcast.xml`は空seedであり履歴を追記しない。
- native appなのでDockerを使わない。release signing/notarizationとlocal ad-hoc buildを混同しない。

変更後はSwift test、build、必要ならevent tap/Accessibilityの実機確認を行う。コメントは周囲の密度と言語へ合わせる。
