# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

⌘IME (Command IME) is a lightweight macOS menu bar app that switches between alphanumeric and kana input using left/right Command keys, with fully configurable key mappings.

**Version**: Defined in `manifest.toml` → `[project].version` (source of truth)  
**Language**: Swift (Swift Package Manager)  
**Target**: macOS 13.0+, arm64

## Build Commands

All commands run from `apps/cmd-ime-swift/`:

```bash
cd apps/cmd-ime-swift

# Build debug
swift build

# Build release
swift build -c release

# Run all tests
swift test

# Run a single test class
swift test --filter KeyEventTests

# Run a single test method
swift test --filter KeyEventTests/testKeyDown_RemapsEvent_WhenMappingExists

# Lint (requires swiftlint installed)
swiftlint

# Create release .app bundle (reads version from manifest.toml)
CMDIME_BUILD_MODE=local ./scripts/package.sh
```

## Architecture

### Event Pipeline

```
CGEvent tap (system-wide)
  └── KeyEvent.eventCallback()
        ├── MediaKeyEvent?  → mediaKeyDown/Up
        ├── flagsChanged    → modifierKeyDown/Up (tracks lone-modifier gestures)
        ├── keyDown         → keyDown → convertedEvent()
        └── keyUp           → keyUp  → convertedEvent()
                                  └── findMapping() → shortcutList[keyCode]
                                        ├── passThrough  (no mapping)
                                        ├── disable      (output keyCode == 999)
                                        └── remap        (mutate CGEvent fields)
```

`KeyEvent` reads only from global caches (`shortcutList`, `exclusionAppsDict`) in the hot path. These caches are written by `AppSettings` on the main thread whenever settings change.

### Settings Architecture

`AppSettings` (singleton, `@MainActor`) is the single source of truth for user preferences. It:
- Wraps `UserDefaults` and publishes `@Published` properties via Combine
- Keeps the legacy globals (`keyMappingList`, `shortcutList`, `exclusionAppsList`, `exclusionAppsDict` in `KeyMappings.swift` / `KeyEvent.swift`) in sync
- Handles UserDefaults key migration from legacy typos (`lunchAtStartup` → `launchAtStartup`)
- Manages `SMAppService` for login item registration

SwiftUI settings views (`Settings/`) observe `AppSettings.shared` directly.

### Global Mutable State

`KeyMappings.swift` declares module-level globals that `KeyEvent` reads on every keystroke:

| Global | Written by | Read by |
|--------|-----------|---------|
| `keyMappingList` | `AppSettings.$keyMappings` sink | `keyMappingListToShortcutList()` |
| `shortcutList` | `keyMappingListToShortcutList()` | `KeyEvent.findMapping()` |
| `exclusionAppsList` | `AppSettings.$exclusionApps` sink | `ExclusionsSettingsView` |
| `exclusionAppsDict` | `AppSettings.$exclusionApps` sink | `KeyEvent.eventCallback()` |
| `activeAppsList` | `KeyEvent.setActiveApp()` | `ExclusionsSettingsView` (app picker) |
| `isRecordingShortcut` | `KeyRecorderSheet` | `KeyEvent.eventCallback()` |

### Key Code Conventions

- **keyCode 999** — sentinel meaning "disable / swallow this key"
- **keyCode 1000+** — media keys (actual media keyCode + 1000)
- **keyCode 54** — Right Command, **55** — Left Command
- **keyCode 102** — Eisu (alphanumeric), **104** — Kana

### CGEvent Tap Reliability

The tap can be disabled by macOS (e.g., on input-source change). `KeyEvent` handles this with:
1. A 5-second heartbeat timer (`tapHeartbeat`) that re-enables the tap if found disabled
2. Retry logic (up to 30 attempts, 1s apart) when `CGEvent.tapCreate` returns nil post-Accessibility grant
3. `BundleWatcher` — watches the main executable for `delete/rename` events to detect `brew upgrade` replacing the bundle

## Release Flow

1. Update `manifest.toml` → `[project].version`
2. Open a PR and merge to `main` → CI (`release.yml`) triggers on PR merge and detects the new version tag does not exist
3. CI runs `scripts/package.sh` (builds, signs, bundles `CmdIME.app`)
4. Creates DMG, optionally notarizes, creates GitHub Release
5. Updates `agiletec-inc/homebrew-tap` Casks/cmd-ime.rb via squash-merged PR

The Sparkle auto-update feed is at `appcast.xml` on the `main` branch (referenced in `Info.plist` via `SUFeedURL`).
