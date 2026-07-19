# ⌘IME Mac App Store 化 設計・ロードマップ

## 目的

⌘IME のソースコードと通常配布版はオープンソースとして公開し、同じ製品を Mac App Store でも有料アプリとして提供する。

- 日本: 300円
- 海外: 約 $2 の App Store 価格帯
- 販売方式: 無料アプリ + IAP ではなく、App Store の有料アプリ
- 主目的: 日本語入力切替の実用性、Apple の署名・Sandbox・審査・TestFlight 運用の実証
- 製品価値: 寄付ではなく、購入者が安心して使い続けられる公式配布版への応援購入

価格は App Store Connect の価格帯に従って設定し、コード内に価格ロジックを持たせない。

この文書では、前段の会話で示された「global は $2」を海外価格帯の意味として扱う。実際の各国価格は App Store Connect の価格表と税・為替設定で確定する。

## Apple公式リファレンス

この設計の根拠にした現行SDK/APIおよび審査資料は以下である。APIの存在だけではIME切替の成功を保証しないため、互換性は受け入れテストで判定する。

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox)
- [Configuring the macOS App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox)
- [CGPreflightListenEventAccess](https://developer.apple.com/documentation/coregraphics/cgpreflightlisteneventaccess)
- [CGRequestListenEventAccess](https://developer.apple.com/documentation/coregraphics/cgrequestlisteneventaccess)
- [CGEventTapCreate](https://developer.apple.com/documentation/coregraphics/cgevent/tapcreate%28tap%3Aplace%3Aoptions%3Aeventsofinterest%3Acallback%3Auserinfo%3A%29)
- [CGEventTapOptions.listenOnly](https://developer.apple.com/documentation/coregraphics/cgeventtapoptions/listenonly)
- [CGEventType.flagsChanged](https://developer.apple.com/documentation/coregraphics/cgeventtype/flagschanged)
- [TISSelectInputSource](https://developer.apple.com/documentation/carbon/text_input_source_services/1452583-tisselectinputsource)
- [NSEvent.addGlobalMonitorForEvents](https://developer.apple.com/documentation/appkit/nsevent/addglobalmonitorforevents%28matching%3Ahandler%3A%29)

App Store配布時のキーボード監視と権限の扱いには、Apple DTSの補足回答も参照する: [Watching keyboard events in a sandboxed app](https://developer.apple.com/forums/thread/789896)。

## 製品境界

⌘IME は汎用キーボードリマッパーではなく、Command キーの単独タップを日本語入力切替に使う小さなメニューバーアプリに限定する。

### 残す機能

- 左 Command の単独タップ → 英数
- 右 Command の単独タップ → かな
- Command + 他キーは通常動作
- ユーザーが切替キーを変更できる場合は、単独 modifier の範囲に限定する
- ログイン時に起動
- 最小限の設定、権限状態、ヘルプ、バージョン情報
- ユーザー設定のローカル保存

### 削除する機能

- Per-app 入力ソース記憶
- Smart モードと入力欄の自動判定
- URL、email、電話番号、郵便番号などのフィールド判定
- アプリ除外リストと最近使ったアプリ一覧
- `AXUIElement`、`AXObserver`、`AXIsProcessTrusted`
- `NSEvent.addGlobalMonitorForEvents`
- 入力内容、アプリ名、入力履歴の収集・保存
- 汎用キー、メディアキーのリマップ機能

設定の保存は必要だが、保存対象はキー設定とアプリ設定だけにする。

## イベント・IME切替設計

### 第1候補

Apple の Core Graphics API を最小範囲で使う。

1. `CGPreflightListenEventAccess` で監視権限を確認する
2. 必要時だけ `CGRequestListenEventAccess` を呼ぶ
3. `CGEvent.tapCreate` を `CGEventTapOptions.listenOnly` で作成する
4. `eventsOfInterest` は `CGEventType.flagsChanged` のみにする
5. 左右 Command の keyCode と modifier 状態だけを判定する
6. `TISSelectInputSource` で英数・かな切替を試す

`listenOnly` はイベントを変更・破棄しない passive listener である。入力文字や他のキーイベントを読む設計にはしない。

### フォールバック

`TISSelectInputSource` が Kotoeri、Google 日本語入力、ATOK のいずれかで実際の入力モードを切り替えられない場合だけ、イベント送信方式を別 Issue で検証する。

- `CGEventTapPostEvent`
- `CGPreflightPostEventAccess`
- `CGRequestPostEventAccess`

Post Event 権限を最初から要求しない。必要性が実機テストで確認された場合に限り採用可否を決める。

### 禁止事項

- `AXIsProcessTrustedWithOptions` による自動権限要求
- `NSEvent` の global key monitor
- 起動直後の無条件 event tap 作成
- 権限待ちの無限リトライ
- 権限失敗時のメインスレッドブロック
- モーダルダイアログでの復旧待ち

## 権限フロー

起動時は権限を要求せず、現在の状態だけを表示する。

```text
起動
  ↓
設定画面で権限状態を表示
  ↓
ユーザーが「有効にする」を押す
  ↓
CGPreflightListenEventAccess
  ↓ 未許可
CGRequestListenEventAccess
  ↓
ユーザーがシステム設定で許可
  ↓
event tapを1回だけ作成
```

権限拒否、キャンセル、TCC反映遅延、event tap作成失敗は、アプリを終了・再起動せず、停止状態として設定画面に表示する。

開発ビルドには event tap を無効化して起動する緊急停止フラグを持たせる。

## 配布設計

### App Store版

- App Sandbox 必須
- App Store 署名・archive・TestFlight 経由
- Sparkle 不使用
- GitHub appcast 不使用
- DMG/Homebrew installer 不使用
- App Store の自動更新を使用

### 直接配布版

- Homebrew/DMG を既存ユーザー向けに維持する
- Sparkle は直接配布ターゲットにのみ残せる
- App Store版と bundle/entitlement/build setting を混在させない

## データ・プライバシー

⌘IME は以下を収集・送信・保存しない。

- 入力文字
- キー入力履歴
- アクティブアプリ名
- ウィンドウ名
- 入力欄の内容
- ユーザー識別子
- ネットワーク上の利用データ

保存するのは、ユーザーが明示的に変更した設定だけである。プライバシーポリシーにもこの境界を記載する。

## 検証戦略

ホストMacの権限を使う前に、Xcodeの単体テストとmacOS VMで全受け入れテストを通す。

### 層1: Xcode単体テスト

- `flagsChanged` の左右Command判定
- 単独タップとCommand + 他キーの区別
- 連打、長押し、modifier併用
- 権限状態の状態遷移
- event tap失敗時の停止処理
- TIS切替成功・失敗のmock
- 設定保存
- 入力データを保存しないこと

### 層2: Sandbox macOS VM

- App Sandbox署名済みアプリの起動
- 初回起動時に権限を勝手に要求しない
- 権限拒否・キャンセル・許可
- 権限剥奪後の復旧
- event tap作成失敗
- macOS再起動・ログアウト・スリープ復帰
- Kotoeriの英数/かな切替
- アプリ終了後にevent tapが残らないこと
- メインスレッドがブロックされないこと

### 層3: TestFlight

- App Store署名・Sandbox・archive
- VMで通った全権限シナリオ
- App Store配布経路でのTCC挙動
- App Store更新

### 層4: ホストMac最終確認

VMとTestFlightの受け入れテストが全て通った後にのみ実施する。

- Kotoeri
- Google 日本語入力
- ATOK
- 実キーボードの左右Command
- Terminal、ブラウザ、エディタ、パスワード欄

「たぶん動く」は合格条件にしない。未検証の項目は未完了として扱う。

現時点では、VM/TestFlight/ホストMacの受け入れテストは未実施であり、設計上の候補を確定実装とみなさない。

## ロードマップ

### Phase 0: 設計と安全な検証基盤

1. イベント監視・権限・IME切替をprotocol境界に分離
2. 開発用bundle IDとevent tap無効化フラグを追加
3. Xcode単体テストを追加
4. macOS Sandbox VMを用意

### Phase 1: 最小機能化

1. AXUIElement/Smart/Per-app/Exclusionsを削除
2. `flagsChanged` のみを扱うevent tapへ変更
3. `TISSelectInputSource` のKotoeri/Google/ATOK互換性を検証
4. 必要ならPost Event方式を別途評価

### Phase 2: App Store製品化

1. App Store用Xcodeターゲットとentitlements
2. Sparkle分離
3. 初回権限・設定画面の再設計
4. 日本語・英語ローカライズ
5. プライバシー、サポート、ストアメタデータ

### Phase 3: 審査実証

1. TestFlight配布
2. Sandbox/TCC/IME受け入れテスト
3. App Review提出
4. 審査指摘をIssue化

## 最初のIssueドラフト

### `architecture: flagsChanged + TISSelectInputSourceの最小IME切替を検証する`

#### Problem / outcome

現在の⌘IMEは全キー・メディアキーのevent tap、Accessibility API、アプリ監視、合成キー送信を組み合わせている。App Store版では、左右Commandの単独タップだけを検知し、まず公開APIの`TISSelectInputSource`で切替できる最小構成を確立する。

#### Scope

- `flagsChanged` のみを監視するadapter
- `listenOnly` event tap
- `CGPreflightListenEventAccess` / `CGRequestListenEventAccess`
- `TISSelectInputSource` adapter
- Kotoeri、Google 日本語入力、ATOKの実機検証用テスト手順
- 権限拒否・tap失敗時の停止状態

#### Non-goals

- Per-app/Smart/Exclusions
- 汎用キーリマップ
- Post Event権限の採用
- App Store提出そのもの

#### Acceptance criteria

- [ ] AC-1: `flagsChanged` 以外をevent tapの監視対象に含めない。
- [ ] AC-2: 権限未許可時にevent tapを作成せず、メインスレッドをブロックしない。
- [ ] AC-3: 左右Commandの単独タップだけを検知し、Command + 他キーを切替扱いしない。
- [ ] AC-4: Accessibility APIと`NSEvent.addGlobalMonitorForEvents`を使用しない。
- [ ] AC-5: Sandbox有効のmacOS VMでKotoeriの英数/かな切替が成功する。
- [ ] AC-6: Google 日本語入力またはATOKで切替不能な場合、その結果と失敗条件を記録し、Post Event方式を未検証のまま採用しない。
- [ ] AC-7: 権限拒否、権限剥奪、event tap作成失敗、スリープ復帰でアプリがフリーズ・再起動要求状態にならない。

#### Verification

| Criterion | Verification | Expected |
|---|---|---|
| AC-1 | `swift test` + source inspection | flagsChangedのみ |
| AC-2 | Xcode permission-state tests + VM fresh snapshot | UI responsive; tap未作成 |
| AC-3 | injected event sequence tests + VM keyboard test | 単独Commandだけ切替 |
| AC-4 | `rg` source audit | AX/NSEvent global monitorなし |
| AC-5 | VM sandbox signed build | Kotoeri切替成功 |
| AC-6 | VM IME matrix | 成否と理由を記録 |
| AC-7 | VM fault-injection matrix | freeze/restartなし |

#### Dependencies

- Sandbox VM
- App Store相当の署名済み開発ビルド
- Kotoeri
- Google日本語入力/ATOKの検証環境
