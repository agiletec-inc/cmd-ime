# CLAUDE.md

**IMPORTANT: This project uses `manifest.toml` as the single source of truth.**

All project rules, policies, workflows, versioning requirements, and agent execution guidelines are defined in:

📋 **`manifest.toml`**

Please read `manifest.toml` for:
- Version management policies (REQUIRED: bump version on source changes)
- Implementation workflows (REQUIRED: check official docs before implementing)
- Command policies (forbidden commands and required wrappers)
- Critical implementation notes
- Agent execution rules

---

## Quick Reference

This file provides supplementary guidance for Claude Code (claude.ai/code).

## Project Overview

⌘IME (Command IME) is a lightweight macOS app that switches between alphanumeric and kana input using left/right Command keys. The app is optimized for Apple Silicon.

**Key Features**:
- Native arm64 build for M1/M2/M3/M4 Macs
- Minimal resource usage (< 50MB memory, < 1% CPU idle)
- Instant key switching without delay
- Customizable key mappings via preferences
- Login item support for automatic startup
- App exclusion list for selective behavior

**Based on**: Original [cmd-eikana](https://github.com/imasanari/cmd-eikana) project

### Repository Structure

This is a monorepo containing multiple applications:

```
cmd-ime/
├── apps/
│   ├── cmd-ime-rust/    # Rust/Tauri desktop app (PRIMARY)
│   └── landing/         # Next.js landing page with webui
├── libs/                # Shared libraries (empty for now)
└── docs/                # Documentation (VISION.md, ROADMAP.md, etc.)
```

**Primary Development Target**: `apps/cmd-ime-rust/` - Rust/Tauri implementation (v3.2.0)
**Landing Page**: `apps/landing/` - Next.js marketing site with embedded webui (for comparison, will be deprecated when desktop app is complete)

**Default Development**: All new work should focus on `apps/cmd-ime-rust/`.

## Build Commands

### Rust/Tauri Development (Primary)

```bash
# Navigate to Rust project
cd apps/cmd-ime-rust

# Install dependencies (first time only)
pnpm install

# Development mode with hot reload
pnpm tauri dev

# Build release version
pnpm tauri build

# Build will create .app in:
# apps/cmd-ime-rust/src-tauri/target/release/bundle/macos/
```

### Swift/Cocoa (Legacy - Reference Only)

#### Development Build (Xcode)
```bash
# Debug build
xcodebuild -configuration Debug build

# Release build
xcodebuild -configuration Release build

# Clean build folder
xcodebuild clean -scheme "⌘IME" -configuration Debug
```

### Swift Package Manager (SPM)
```bash
# Build library target (limited - excludes AppDelegate due to @NSApplicationMain)
swift build

# Run tests via SPM
swift test

# Note: Package.swift is configured for testing only
# Full app build requires Xcode due to @NSApplicationMain and UI components
```

### Testing
```bash
# Run all tests with coverage
./run_tests.sh

# Run diagnostic tests only
xcodebuild test -scheme "⌘IME" -only-testing:CmdIMETests/DiagnosticTests

# Run specific test suite
xcodebuild test -scheme "⌘IME" -only-testing:CmdIMETests/KeyEventTests

# Generate coverage report
xcodebuild test -scheme "⌘IME" -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
xcrun xccov view --report TestResults.xcresult
```

### DMG Creation
```bash
# Create distributable DMG
./create_dmg_simple.sh

# Alternative DMG creation (with custom options)
./create_dmg.sh
```

## Architecture Overview

### Rust/Tauri Architecture (Primary)

**Tech Stack**:
- **Backend**: Rust (system-level key event handling)
- **Frontend**: Tauri v2.8.4 with HTML/CSS/JavaScript
- **Build**: Cargo + pnpm

**Core Components** (`apps/cmd-ime-rust/src-tauri/src/`):
- `event_tap.rs` - CGEvent tap implementation for key interception
- `ime.rs` - IME switching logic (alphanumeric ↔ kana)
- `settings.rs` - Application settings management
- `lib.rs` - Tauri command handlers and app initialization
- `main.rs` - Application entry point

**Key Architecture Decisions**:
- Native Rust for performance-critical key event handling
- Tauri for cross-platform UI framework
- CGEvent tap for system-wide key monitoring (same as Swift version)
- Settings stored in Tauri's built-in storage

**Development Workflow**:
1. Navigate to app: `cd apps/cmd-ime-rust`
2. Modify Rust backend: `src-tauri/src/`
3. Modify frontend UI: `src/`
4. Run `pnpm tauri dev` for hot reload
5. Build with `pnpm tauri build` for release

---

### Swift/Cocoa Architecture (Legacy Reference)

#### Two-Target Structure

**Main App (⌘IME.app)**:
- `AppDelegate.swift` - Application lifecycle, menu bar, preferences
- `KeyEvent.swift` - Core key event monitoring and conversion engine
- `PreferenceWindowController.swift` - Preferences UI controller
- `ShortcutsController.swift` - Key mapping management
- `ExclusionAppsController.swift` - App exclusion list management
- `KeyboardShortcut.swift` - Keyboard shortcut representation and operations
- `KeyTextField.swift` - Custom text field for key capture
- `MappingMenu.swift` - Key mapping menu UI
- `MediaKeyEvent.swift` - Media key event handling
- `AppData.swift` - Data models for apps and settings
- `KeyMapping.swift` - Key mapping data structure
- `toggleLaunchAtStartup.swift` - Login item management
- `ViewController.swift` - Main view controller

**Helper App (cmd-ime-helper.app)**:
- Objective-C helper embedded in main app bundle
- Located in `Contents/Library/LoginItems/`
- Handles automatic startup functionality

### Core Components

#### KeyEvent.swift (Core Engine)
The heart of the application - monitors keyboard events via CGEvent tap and converts keys based on user-defined mappings.

**Key Responsibilities**:
- Accessibility permission management (first-launch prompt only)
- CGEvent tap creation for system-wide key monitoring
- Modifier key detection (Command, Shift, Control, Option, Fn)
- Key event conversion based on mappings
- App-aware behavior (respects exclusion list)
- Media key support

**Important Implementation Details**:
- Uses both NSEvent and CGEvent to avoid mouse drag bugs
- Implements timer-based waiting for accessibility permission
- Stores active apps list (max 10) for quick switching
- Supports modifier-only mappings (e.g., single Command key press)

#### AppDelegate.swift (Lifecycle)
Application initialization, menu bar setup, and settings persistence.

**Key Responsibilities**:
- UserDefaults loading/saving for all settings
- Login item preference management
- Status bar menu creation and management
- Preference window coordination
- Restart/quit functionality

**Settings Persistence**:
- `launchAtStartup` - Login item enabled/disabled
- `exclusionApps` - Array of excluded app data
- `mappings` - Key mapping configurations
- Legacy migration from v2.0.x `oneShotModifiers` format

#### KeyboardShortcut.swift (Key Representation)
Represents keyboard shortcuts with keyCode + modifier flags.

**Capabilities**:
- CGEvent → KeyboardShortcut conversion
- Human-readable string representation
- CGEvent posting for key simulation
- Modifier coverage checking for mappings

### Test Architecture

**Test Coverage Target**: 80% code coverage across all 14 source files

**Test Structure**:
- `DiagnosticTests.swift` - App initialization and permission checks
- `KeyEventTests.swift` - Core key event handling (highest priority)
- `AppDelegateTests.swift` - Lifecycle and menu management
- `IntegrationTests.swift` - End-to-end workflows
- Additional unit tests for all remaining components

**Running Tests**:
All test files exist but require Xcode test scheme configuration to execute. See QUALITY_REPORT.md for status.

## Development Guidelines

### Rust/Tauri Development Environment

**Primary Development Stack**:
- Rust toolchain (rustc, cargo)
- Node.js and pnpm (for Tauri frontend)
- Xcode Command Line Tools (for macOS APIs)

**Setup**:
```bash
# Install Rust (if not installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Tauri CLI globally
cargo install tauri-cli

# Or use pnpm scripts (recommended)
cd apps/cmd-ime-rust
pnpm install
pnpm tauri dev
```

**Key Files**:
- `apps/cmd-ime-rust/src-tauri/Cargo.toml` - Rust dependencies
- `apps/cmd-ime-rust/src-tauri/tauri.conf.json` - Tauri configuration
- `apps/cmd-ime-rust/package.json` - Frontend dependencies and scripts

---

### Swift/Cocoa Environment (Legacy)

**macOS Native Development**:
- This is a macOS-native application (not Docker-based)
- Xcode required for full app development
- All commands run directly on macOS host
- Swift Package Manager available for limited testing

**Workspace Context**:
- Part of `~/github/` workspace but standalone project
- No Docker/Traefik integration (unlike other projects in workspace)
- No Makefile-first development (standard Xcode workflow)

### Xcode Project Structure

**Schemes**:
- `⌘IME` - Main app build and test
- `⌘英かな` - Legacy scheme name
- `cmd-ime-helper` - Helper app target
- `CmdIMETests` - Test suite

**Deployment Target**: macOS 14.0 (Sonoma) or later
**Swift Version**: 5.0
**Architecture**: Universal (arm64 + x86_64)

### Critical Implementation Notes

**Accessibility Permission Handling**:
```swift
// IMPORTANT: Only show permission prompt on first launch
// Subsequent launches wait silently via Timer until permission granted
let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasRequestedAccessibility")
if isFirstLaunch {
    AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])
    UserDefaults.standard.set(true, forKey: "hasRequestedAccessibility")
}
```

**Login Item Management**:
```swift
// IMPORTANT: Login item code was commented out but restored in v3.1.0
// Do not comment out setLaunchAtStartup() calls
setLaunchAtStartup(true)  // Enable by default on first launch
```

**Key Event Conversion Flow**:
1. CGEvent received via event tap callback
2. Check if current app is in exclusion list → pass through if excluded
3. Check if KeyTextField is active → capture key for preferences UI
4. Check mappings via `hasConvertedEvent()` → convert if match found
5. Return modified or original event

### Code Quality Standards

**Memory Management**:
- No memory leaks detected in current implementation
- Proper retain/release for CGEvent tap observers
- Timer invalidation on permission grant

**Performance Requirements**:
- Startup time: < 1 second
- Key event response: < 10ms
- Memory usage: < 50MB idle
- CPU usage: < 1% idle

### DMG Distribution

**v3.1.0 Critical Fixes**:
- DMG-installed apps now work correctly (accessibility permissions)
- First-launch accessibility prompt behavior fixed
- Login item functionality restored

**DMG Creation Notes**:
- Use `create_dmg_simple.sh` for basic DMG
- Output: `CommandIME-{version}.dmg` in project root
- Manual installation: Drag to Applications folder, right-click → Open (first time)

## Common Development Tasks

### Rust/Tauri Development

#### Adding New Key Mapping Features
1. Update `settings.rs` - Add new mapping data structures
2. Modify `event_tap.rs` - Update key conversion logic
3. Update `ime.rs` - Add IME switching logic if needed
4. Update frontend UI in `src/` for settings interface
5. Add Tauri commands in `lib.rs` for frontend-backend communication
6. Test with `pnpm tauri dev`

#### Modifying UI Settings
1. Edit HTML/CSS/JS in `apps/cmd-ime-rust/src/`
2. Update Tauri commands in `src-tauri/src/lib.rs`
3. Hot reload with `pnpm tauri dev` to see changes
4. Build production version with `pnpm tauri build`

#### Debugging Rust Backend
```bash
# Navigate to app
cd apps/cmd-ime-rust

# Run with debug logs
RUST_LOG=debug pnpm tauri dev

# Build debug version
cargo build --manifest-path=src-tauri/Cargo.toml

# Run tests
cargo test --manifest-path=src-tauri/Cargo.toml
```

---

### Swift/Cocoa (Legacy Reference)

#### Adding New Key Mapping Features
1. Update `KeyMapping.swift` data structure
2. Modify `KeyEvent.swift` conversion logic in `getConvertedEvent()`
3. Update `ShortcutsController.swift` UI if needed
4. Add tests to `KeyEventTests.swift` and `IntegrationTests.swift`
5. Update UserDefaults serialization in `AppDelegate.swift`

### Modifying Menu Bar Behavior
1. Edit `setupStatusBarMenu()` and `setupMenuItems()` in `AppDelegate.swift`
2. Add action methods with `@IBAction` attribute
3. Update menu state based on settings changes
4. Test with `AppDelegateTests.swift`

### Adding App Exclusion Features
1. Modify `ExclusionAppsController.swift` for UI changes
2. Update `exclusionAppsDict` handling in `KeyEvent.swift`
3. Ensure UserDefaults persistence in `AppDelegate.swift`
4. Add tests to `ExclusionAppsControllerTests.swift`

## Known Issues and Migration Status

### Rust/Tauri Implementation (v3.2.0)

**Current Development Status**:
- Core event tap implementation: ✅ Complete
- IME switching logic: ✅ Complete
- Settings management: ✅ Complete
- UI frontend: 🔄 In progress
- DMG distribution: ⏳ Pending

**Active Issues**:
- Tauri UI needs completion
- macOS Sequoia compatibility testing required
- Performance benchmarking vs Swift version

---

### Swift/Cocoa Legacy (v3.1.0)

**Fixed in v3.1.0**:
- ✅ DMG installation accessibility permission issues
- ✅ Overly aggressive accessibility permission prompts
- ✅ Login item functionality (code was commented out)

**Known Issues** (not being fixed - use Rust version):
- Exclusion app list UI has minor usability issues
- Test scheme requires Xcode configuration before tests can run
- Mouse drag bug workaround (NSEvent + CGEvent hybrid approach)
- macOS Sequoia compatibility uncertain

## File Organization

### Rust/Tauri Implementation (Active Development)
**Directory**: `apps/cmd-ime-rust/` - Complete Tauri project
**Source**: `apps/cmd-ime-rust/src-tauri/src/` - Rust source files
  - `event_tap.rs` - CGEvent tap handling (core functionality)
  - `ime.rs` - IME switching logic
  - `settings.rs` - Settings management
  - `lib.rs` - Tauri commands and app initialization
  - `main.rs` - Application entry point
**Frontend**: `apps/cmd-ime-rust/src/` - HTML/CSS/JS for Tauri UI
**Config**: `apps/cmd-ime-rust/src-tauri/tauri.conf.json` - Tauri app configuration
**Dependencies**:
  - `apps/cmd-ime-rust/src-tauri/Cargo.toml` - Rust dependencies
  - `apps/cmd-ime-rust/package.json` - Frontend dependencies and Tauri build scripts

### Landing Page (Next.js)
**Directory**: `apps/landing/` - Marketing site with embedded webui
**Purpose**: Comparison and demonstration (will be deprecated when desktop app is complete)
**Tech Stack**: Next.js, TypeScript, Tailwind CSS
**Status**: Preserved for reference, not actively maintained

---

### Swift/Cocoa Implementation (Legacy)
**Source**: `cmd-ime/` directory contains all Swift source files
**Tests**: `CmdIMETests/` directory with 16 test files (all created, execution pending)
**Helper**: `cmd-ime-helper/` directory with Objective-C helper app
**Scripts**: Root directory contains build and test automation scripts
**Assets**: `cmd-ime/Assets.xcassets` for app icon and resources
**Storyboards**: `cmd-ime/Base.lproj/Main.storyboard` for preference window UI
**Xcode Project**: `CmdIME.xcodeproj` for Xcode development
**SPM Package**: `Package.swift` for limited SPM testing support

## Version Information

### Rust/Tauri Implementation (Active)
**Current Version**: 3.2.0
**Tauri Version**: 2.8.4
**Rust Edition**: 2021
**Minimum macOS**: 14.0 (Sonoma)
**Architecture**: Universal (arm64 + x86_64)

### Swift/Cocoa Implementation (Legacy)
**Legacy Version**: 3.1.0
**Bundle Identifier**: `com.kazuki.cmd-ime`
**Helper Bundle ID**: `com.kazuki.cmd-ime-helper`
**Minimum macOS**: 14.0 (Sonoma)
**Swift Version**: 5.9+
**Xcode**: 15.0+
**Architecture**: Universal (arm64 + x86_64)

### General
**License**: MIT
**Repository**: Monorepo with apps/ and libs/ structure

## Reference Documentation

### Rust/Tauri Resources
- **Tauri Documentation**: [tauri.app](https://tauri.app)
- **Rust macOS APIs**: Core Graphics, Core Foundation bindings
- **Project README**: `apps/cmd-ime-rust/README.md` (Tauri-specific setup)

### Legacy Swift/Cocoa Resources
- **Quality Report**: `QUALITY_REPORT.md` - Test coverage status (Swift implementation)
- **DMG Options**: `DMG_OPTIONS.md` - Distribution packaging (Swift implementation)
- **Original Project**: [cmd-eikana](https://github.com/imasanari/cmd-eikana) - Historical context

### General
- **Repository Type**: Monorepo with multiple apps (apps/cmd-ime-rust, apps/landing)
- **Architecture**: Standalone macOS app development (no Docker/Traefik like other workspace projects)
