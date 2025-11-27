# CLAUDE.md

## Project Overview

⌘IME (Command IME) is a lightweight macOS app that switches between alphanumeric and kana input using left/right Command keys.

**Version**: 1.2.0
**Language**: Swift (Swift Package Manager)
**Target**: macOS 13.0+
**Architecture**: arm64 (Apple Silicon)

## Repository Structure

```
cmd-ime/
├── apps/
│   └── cmd-ime-swift/    # Swift implementation (SPM)
│       ├── Sources/CmdIMESwift/
│       ├── Tests/CmdIMESwiftTests/
│       ├── scripts/
│       └── Package.swift
├── manifest.toml         # Project metadata (source of truth)
├── CLAUDE.md             # This file
├── README.md             # User-facing documentation
└── LICENSE               # MIT License
```

## Build Commands

```bash
cd apps/cmd-ime-swift

# Build
swift build -c release

# Run tests
swift test

# Create DMG (requires build first)
./scripts/build_app.sh && ./scripts/package.sh
```

## Source Files

**Core** (`apps/cmd-ime-swift/Sources/CmdIMESwift/`):
- `CmdIMEApp.swift` - Application entry point, menu bar setup
- `KeyEvent.swift` - CGEvent tap for system-wide key monitoring
- `KeyboardShortcut.swift` - Key representation and conversion
- `KeyMapping.swift` - Key mapping data structure
- `PreferenceWindowController.swift` - Settings window
- `ShortcutsController.swift` - Key mapping UI
- `ExclusionAppsController.swift` - App exclusion list
- `toggleLaunchAtStartup.swift` - Login item management
- `checkUpdate.swift` - Version update check

## Key Architecture

1. **CGEvent Tap** - System-wide keyboard monitoring
2. **Text Input Source API** - IME switching (alphanumeric ↔ kana)
3. **UserDefaults** - Settings persistence
4. **Menu Bar** - Status item with dropdown menu

## Development Notes

- Requires Accessibility permission (System Settings > Privacy & Security > Accessibility)
- Default mappings: Left Command → Alphanumeric, Right Command → Kana
- App exclusion list prevents IME switching in specified apps

## Version Management

`manifest.toml` is the source of truth for version. Update `[project].version` and `[versioning].source` when releasing.
