# Changelog

All notable changes to ⌘IME will be documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Version bumps are derived from [Conventional Commits](https://www.conventionalcommits.org/)
on the `main` branch via `.github/workflows/release.yml`.

## [Unreleased]

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

[Unreleased]: https://github.com/agiletec-inc/cmd-ime/compare/v1.3.4...HEAD
[1.3.4]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.3.4
[1.3.3]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.3.3
[1.3.2]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.3.2
[1.3.1]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.3.1
[1.3.0]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.3.0
[1.2.5]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.2.5
[1.2.0]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.2.0
