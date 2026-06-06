# Changelog

All notable changes to ⌘IME will be documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Version bumps are derived from [Conventional Commits](https://www.conventionalcommits.org/)
on the `main` branch via `.github/workflows/release.yml`.

## [Unreleased]

## [2.4.1] - 2026-06-06

### Added
- **Preferences window keyboard shortcuts** — a minimal main menu gives the window
  ⌘W (close), ⌘M (minimize), and standard Cut/Copy/Paste/Select All in text fields.
  ⌘Q closes the window and keeps ⌘IME in the menu bar by default; a new
  **"Quit ⌘IME with ⌘Q"** toggle (General settings) opts into a full quit. The menu
  bar "Quit" item always terminates.

### Changed
- The release workflow fails before publishing if the build's code-signing
  `TeamIdentifier` drifts from `CMDIME_EXPECTED_TEAM_ID`, since a team change breaks
  Sparkle auto-updates for already-installed users.

## [2.4.0] - 2026-06-06

### Added
- **Gentle update reminders** — as an `LSUIElement` menu bar agent, ⌘IME now
  brings itself to the foreground while a Sparkle update is on screen and posts
  a Notification Center banner for background/scheduled checks, so new versions
  are noticed without a Dock icon to glance at (`SPUStandardUserDriverDelegate`,
  per Sparkle's gentle-reminders guidance).

### Changed
- Smart input switching re-evaluates the focused field via `AXObserver` instead
  of a 500 ms polling timer — lower idle CPU, immediate response (#67).
- The Sparkle appcast is published to a dedicated `appcast` branch and served
  from its raw URL, so the update feed no longer depends on the latest GitHub
  Release and every entry is retained for delta updates (#68).
- `release.yml` triggers on PR merge instead of push to `main`.
- `Process` launches use `executableURL` instead of the deprecated `launchPath`
  property (#83).
- `KeyEvent.convertedEvent` builds the remapped event on a copy so a tapped
  event is never mutated as a side effect (#94).
- CI runs a release-build smoke test (`package.sh`) on every PR, and
  `Package.resolved` is committed for reproducible dependency resolution and an
  effective SPM cache key (#81, #89).

### Fixed
- Reliability, memory, and correctness fixes across the CGEvent tap, Sparkle
  appcast signing, and the release workflow (#60–#77).
- Sparkle updater start failures are logged instead of silently swallowed (#82).
- Smart-field detection reads `kAXTitleAttribute` (a string) instead of
  `kAXTitleUIElementAttribute` (an element), so title hints are honored (#84).
- Settings lists key SwiftUI `ForEach` on a stable per-row id instead of the
  array index, fixing row-state desync on add/remove/reorder (#85).
- `package.sh` signs `Sparkle.framework` with the hardened runtime so notarized
  builds are accepted (#87).
- The Homebrew cask declares `auto_updates true`, so `brew upgrade` no longer
  conflicts with Sparkle self-updates (#88).

### Removed
- Stale `TEST_REPORT.md` and unused declarations — `exclusionAppsList`,
  `mediaKeyDic`, `MediaKeyEvent.nsEvent` (#86, #93).

## [2.3.2] - 2026-05-10

### Added
- SPM build cache in CI for faster PR runs.

### Changed
- `appcast.xml` is also attached as a GitHub Release asset.

## [2.3.1] - 2026-05-10

### Changed
- In-app updates now use Sparkle's native update UI, replacing the custom
  update dialog.
- `release.yml` appcast generation rewritten in `awk`, removing an inline
  Python heredoc that broke the YAML block scalar.

## [2.3.0] - 2026-05-10

### Added
- **Input switching modes** — General settings offers three modes: Off,
  Per-app (remembers the input source per app), and Smart (Beta — per-app
  memory plus auto-switch to alphanumeric in URL / phone / email / ZIP fields).
- **Exclusions — "Add App…" button** — opens a file picker (defaulting to
  /Applications) so any installed app can be excluded without switching to it
  first.
- **Input key presets** — the Shortcuts tab offers preset Key/Action menus,
  including IME-only virtual keys (英数 keyCode 102, かな keyCode 104) that
  cannot be recorded on keyboards without physical 英数/かな keys.

### Changed
- **Shortcuts tab** — Key / Action column layout with preset-only dropdown
  menus, replacing the key recorders.
- `NSStatusItem` moved from a global variable to an `AppDelegate` property (#38).
- Release builds accept an Apple Development certificate (not only Developer ID)
  as a stable signing identity.

### Fixed
- Memory, reliability, and correctness fixes across the CGEvent tap and
  login-item handling (#34–#43).

## [2.0.1] - 2026-05-04

### Changed
- Major version bump to 2.0.1 to resolve versioning inconsistencies.


### Added
- `apps/cmd-ime-swift/scripts/generate-self-signed-cert.sh` — helper script to generate
  a self-signed code-signing certificate for stable TCC grants without an Apple
  Developer account.
- Optional Notarization support in `release.yml` (gated by `APPLE_ID` secret).
- `BundleWatcher` — the app now detects when its .app bundle is replaced on disk
  (e.g. by `brew upgrade`) and auto-restarts to ensure it runs the new binary.
- "About" section in General settings with version info and project links.

### Fixed
- Release builds now use a stable signing identity with `--timestamp` (Refs #23),
  ensuring macOS TCC keeps Accessibility grants across upgrades.
- Preferences menu item renamed to "⌘IME <version> — Preferences..." for better
  at-a-glance version visibility.
- Standalone About panel removed in favor of the integrated About section.
- Shortcuts UI improved with column headers, edit icons, and tooltips.
- Homebrew cask now uses `signal: [TERM, KILL]` for more reliable uninstalls.

## [1.3.4] - 2026-05-02

### Fixed
- Homebrew cask now `uninstall quit:`s the running ⌘IME agent before
  brew replaces the .app, refreshes LaunchServices to update Finder /
  System Settings, and auto-launches the new build. Previous flow
  required the user to manually quit the old process and re-launch.
  See #6.
- `zap trash:` plist path corrected to `com.kazuki.cmdime.plist` (the
  bundle has no hyphen).

## [1.3.3] - 2026-05-02

### Fixed
- CGEvent tap setup retries on `tapCreate` returning nil (suspected tccd
  race after first Accessibility grant) instead of `exit(1)`. Also
  re-enables the tap if macOS silently disables it. Partial fix for #6.

## [1.3.2] - 2026-05-02

### Removed
- 1589 lines of dead Storyboard / AppKit controller code unused since
  the SwiftUI Preferences rewrite (`ViewController.swift`,
  `ExclusionAppsController.swift`, `ShortcutsController.swift`,
  `KeyTextField.swift`, `MappingMenu.swift`,
  `Resources/Base.lproj/Main.storyboard`).

### Changed
- Last Japanese inline comments translated to English. Only `英数` /
  `かな` physical-key labels remain (those are the names printed on
  the keys, not localizable).

## [1.3.1] - 2026-05-02

### Added
- 13 new tests covering `KeyboardShortcut` modifier semantics,
  `KeyMapping` round-trips, and `AppSettings` migration / persistence.

## [1.3.0] - 2026-05-02

### Added
- SwiftUI Preferences UI with three working tabs (General / Shortcuts
  / Exclusions). `AppSettings` is the single source of truth, wrapping
  UserDefaults and `SMAppService`. Closes the long-standing "Preferences
  is a stub" bug.
- Manual "Check Now" button + on-launch update toggle, both backed by
  the GitHub Releases API.
- `manifest.toml [project].version` is now consulted by `package.sh`,
  so local builds match the declared version.
- README pointer updates, `.github/ISSUE_TEMPLATE/*`, and Discussions
  link.

### Changed
- Update check switched from the dead `ei-kana.appspot.com` endpoint
  to `api.github.com/repos/agiletec-inc/cmd-ime/releases/latest`.
- Migrated UserDefaults keys: `lunchAtStartup` → `launchAtStartup`,
  `checkUpdateAtlaunch` → `checkUpdateAtLaunch` (legacy keys removed
  on first launch).
- README aligned with reality: macOS 13+ minimum, correct repo URL,
  English Login Item / Updates section, no fictional Xcode project,
  fixed uninstall command.

### Removed
- macOS 12 fallback path in `toggleLaunchAtStartup.swift`
  (`SMLoginItemSetEnabled` + non-existent helper bundle).
- `apps/cmd-ime-swift/scripts/build_app.sh` — host-specific dead
  script that copied a Storyboard from one developer's machine.

## [1.2.5] - 2026-05-01

### Changed
- Switch Homebrew cask publish workflow to GitHub App authentication so
  releases no longer depend on a personal access token that expires.

## [1.2.0] - 2025-11-27

### Added
- Initial Swift Package Manager project under `apps/cmd-ime-swift/`.
- `SMAppService.mainApp`-based "Launch at login" implementation
  (`toggleLaunchAtStartup.swift`).
- Code signing in `scripts/package.sh` (ad-hoc).

### Changed
- Renamed the app from `⌘英かな` to `⌘IME`.
- Cleaned up repository structure.

[Unreleased]: https://github.com/agiletec-inc/cmd-ime/compare/v2.3.2...HEAD
[2.3.2]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v2.3.2
[2.3.1]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v2.3.1
[2.3.0]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v2.3.0
[2.0.1]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v2.0.1
[1.3.4]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.3.4
[1.3.3]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.3.3
[1.3.2]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.3.2
[1.3.1]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.3.1
[1.3.0]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.3.0
[1.2.5]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.2.5
[1.2.0]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.2.0
