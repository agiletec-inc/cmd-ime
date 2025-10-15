# ⌘IME - Architecture

**Maintained by**: Agiletec Inc.
**Last Updated**: 2025-10-15
**Version**: v3.2.0 (Rust/Tauri)

---

## 🎯 Architecture Overview

⌘IME is built with **Rust + Tauri** architecture for modern, maintainable, and cross-platform-ready codebase.

```
┌─────────────────────────────────────────────────────────────┐
│                       ⌘IME Application                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐         ┌─────────────────────────┐  │
│  │  Frontend (UI)   │◄───────►│  Backend (Rust)         │  │
│  │                  │  Tauri  │                         │  │
│  │  - HTML/CSS/JS   │ Commands│  - event_tap.rs         │  │
│  │  - Settings UI   │         │  - ime.rs               │  │
│  │  - Key Mapping   │         │  - settings.rs          │  │
│  │  - Menu Bar      │         │  - lib.rs               │  │
│  └──────────────────┘         └─────────────────────────┘  │
│           │                              │                   │
│           │                              │                   │
│           ▼                              ▼                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │            macOS System APIs                        │   │
│  │  - CGEvent (Keyboard Monitoring)                    │   │
│  │  - Text Input Source (IME Switching)                │   │
│  │  - App Services (Active App Detection)             │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Technology Stack

### Frontend
- **Framework**: HTML5 + CSS3 + Vanilla JavaScript
- **Build Tool**: Tauri bundler
- **UI Library**: Native web components
- **Communication**: Tauri IPC commands

### Backend
- **Language**: Rust 2021 edition
- **Framework**: Tauri v2.8.4
- **System APIs**: Core Graphics, Core Foundation
- **Build System**: Cargo

### Platform Integration
- **macOS APIs**:
  - Core Graphics (CGEvent tap)
  - Text Input Source (IME switching)
  - App Services (active app detection)
- **Target**: macOS 14.0+ (Sonoma, Sequoia)
- **Architecture**: Universal (arm64 + x86_64)

---

## 📦 Module Structure

### Rust Backend (`apps/cmd-ime-rust/src-tauri/src/`)

```
apps/cmd-ime-rust/src-tauri/src/
├── main.rs              # Application entry point
├── lib.rs               # Tauri command handlers
├── event_tap.rs         # CGEvent tap implementation
├── ime.rs               # IME switching logic
└── settings.rs          # Configuration management
```

#### `main.rs` - Application Entry Point
```rust
fn main() {
    tauri::Builder::default()
        .setup(|app| {
            // Initialize event tap
            // Start IME monitoring
            // Load settings
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            get_settings,
            update_settings,
            get_key_mappings,
            set_key_mapping,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

#### `event_tap.rs` - CGEvent Tap
**Purpose**: System-wide keyboard event monitoring

```rust
use core_graphics::event::{CGEvent, CGEventTap, CGEventTapLocation, CGEventType};

pub struct EventTap {
    tap: CGEventTap,
    mappings: HashMap<CGKeyCode, KeyMapping>,
}

impl EventTap {
    pub fn new() -> Result<Self, Error> {
        let event_mask = (1 << CGEventType::KeyDown as u64)
            | (1 << CGEventType::KeyUp as u64)
            | (1 << CGEventType::FlagsChanged as u64);

        let tap = CGEventTap::new(
            CGEventTapLocation::HID,
            event_mask,
            |proxy, event_type, event| {
                // Filter and convert events
                handle_event(event_type, event)
            },
        )?;

        Ok(Self { tap, mappings })
    }

    fn handle_event(&self, event_type: CGEventType, event: CGEvent) -> Option<CGEvent> {
        match event_type {
            CGEventType::FlagsChanged => self.handle_modifier_key(event),
            CGEventType::KeyDown => self.handle_key_down(event),
            CGEventType::KeyUp => self.handle_key_up(event),
            _ => Some(event), // Pass through
        }
    }
}
```

**Key Features**:
- Low-level keyboard monitoring via CGEvent tap
- Modifier key detection (Command, Shift, Control, Option, Fn)
- Event filtering (only process relevant keys)
- Pass-through for non-handled events

#### `ime.rs` - IME Switching
**Purpose**: Switch macOS input methods

```rust
use core_foundation::string::CFString;
use carbon::input_source::{TISInputSource, TISInputSourceRef};

pub struct IMEManager {
    alphanumeric_source: TISInputSource,
    hiragana_source: TISInputSource,
}

impl IMEManager {
    pub fn new() -> Result<Self, Error> {
        let alphanumeric = Self::find_input_source("com.apple.keylayout.ABC")?;
        let hiragana = Self::find_input_source("com.apple.inputmethod.Kotoeri.Hiragana")?;

        Ok(Self {
            alphanumeric_source: alphanumeric,
            hiragana_source: hiragana,
        })
    }

    pub fn switch_to_alphanumeric(&self) -> Result<(), Error> {
        self.alphanumeric_source.select()
    }

    pub fn switch_to_hiragana(&self) -> Result<(), Error> {
        self.hiragana_source.select()
    }

    fn find_input_source(id: &str) -> Result<TISInputSource, Error> {
        // Query macOS Text Input Source API
        TISInputSource::find_by_id(CFString::new(id))
    }
}
```

**Key Features**:
- Native macOS Text Input Source API
- Pre-caches input source references
- Fast switching (<10ms)
- Error handling for missing input sources

#### `settings.rs` - Configuration Management
**Purpose**: Persistent settings storage

```rust
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize)]
pub struct Settings {
    pub key_mappings: Vec<KeyMapping>,
    pub excluded_apps: Vec<String>,
    pub launch_at_startup: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct KeyMapping {
    pub input: KeyboardShortcut,
    pub output: IMEAction,
}

impl Settings {
    pub fn load() -> Result<Self, Error> {
        let path = Self::config_path();
        let contents = std::fs::read_to_string(path)?;
        Ok(serde_json::from_str(&contents)?)
    }

    pub fn save(&self) -> Result<(), Error> {
        let path = Self::config_path();
        let contents = serde_json::to_string_pretty(self)?;
        std::fs::write(path, contents)?;
        Ok(())
    }

    fn config_path() -> PathBuf {
        let home = dirs::home_dir().unwrap();
        home.join("Library/Application Support/com.kazuki.cmd-ime/settings.json")
    }
}
```

**Key Features**:
- JSON-based configuration
- Standard macOS Application Support directory
- Type-safe serialization/deserialization
- Default configuration on first launch

#### `lib.rs` - Tauri Command Handlers
**Purpose**: Frontend-backend communication

```rust
use tauri::command;

#[command]
pub fn get_settings() -> Result<Settings, String> {
    Settings::load().map_err(|e| e.to_string())
}

#[command]
pub fn update_settings(settings: Settings) -> Result<(), String> {
    settings.save().map_err(|e| e.to_string())
}

#[command]
pub fn get_key_mappings() -> Result<Vec<KeyMapping>, String> {
    let settings = Settings::load()?;
    Ok(settings.key_mappings)
}

#[command]
pub fn set_key_mapping(mapping: KeyMapping) -> Result<(), String> {
    let mut settings = Settings::load()?;
    settings.key_mappings.push(mapping);
    settings.save()?;
    Ok(())
}

#[command]
pub fn test_ime_switch() -> Result<String, String> {
    let ime = IMEManager::new()?;
    ime.switch_to_alphanumeric()?;
    Ok("Switched to alphanumeric".to_string())
}
```

**Key Features**:
- Type-safe Tauri commands
- Error propagation to frontend
- Simple JSON serialization
- Command discovery via Tauri macro

---

## 🔄 Data Flow

### Key Event Handling Flow

```
1. User presses key
   │
   ▼
2. macOS CGEvent generated
   │
   ▼
3. CGEvent Tap intercepts (event_tap.rs)
   │
   ├──► Not handled → Pass through to system
   │
   └──► Handled → Convert to IME action
        │
        ▼
4. Check active app (app exclusion)
   │
   ├──► Excluded → Pass through
   │
   └──► Not excluded → Process
        │
        ▼
5. Match key mapping (settings.rs)
   │
   ├──► No match → Pass through
   │
   └──► Match found → Execute IME switch
        │
        ▼
6. Switch IME (ime.rs)
   │
   ├──► Alphanumeric (Left Command)
   │
   └──► Hiragana (Right Command)
        │
        ▼
7. Event consumed (not passed to system)
```

### Settings Update Flow

```
1. User changes settings in UI (HTML/CSS/JS)
   │
   ▼
2. Frontend calls Tauri command (invoke)
   │
   ▼
3. Tauri IPC → Backend Rust (lib.rs)
   │
   ▼
4. Parse settings (serde_json)
   │
   ▼
5. Validate settings (settings.rs)
   │
   ▼
6. Write to disk (JSON file)
   │
   ▼
7. Reload event tap with new mappings
   │
   ▼
8. Return success/error to frontend
   │
   ▼
9. UI updates with new state
```

---

## 🎨 Frontend Architecture

### UI Components

```
apps/cmd-ime-rust/src/
├── index.html          # Main window
├── main.js             # Application logic
├── styles.css          # Styling
└── assets/
    ├── icons/          # App icons
    └── images/         # UI assets
```

### Tauri IPC Communication

**Frontend → Backend**:
```javascript
// Get current settings
const settings = await invoke('get_settings');

// Update key mapping
await invoke('set_key_mapping', {
  mapping: {
    input: { keyCode: 55, modifiers: [] }, // Left Command
    output: 'Alphanumeric'
  }
});

// Test IME switch
const result = await invoke('test_ime_switch');
console.log(result); // "Switched to alphanumeric"
```

**Backend → Frontend** (Events):
```javascript
// Listen for IME switch events
await listen('ime-switched', (event) => {
  console.log('IME switched to:', event.payload);
  updateUI(event.payload);
});
```

---

## 🔒 Security & Permissions

### Required Permissions

1. **Accessibility Permission**
   - Required for: CGEvent tap (system-wide keyboard monitoring)
   - Request timing: First launch only
   - User action: Manual approval in System Settings

2. **Input Monitoring**
   - Required for: Detecting active app
   - Request timing: First key event
   - User action: Automatic on first use

### Permission Handling Flow

```rust
fn check_accessibility_permission() -> bool {
    let trusted = AXIsProcessTrusted();
    if !trusted {
        // Show dialog only on first launch
        let is_first_launch = !user_defaults_has_key("hasRequestedAccessibility");
        if is_first_launch {
            AXIsProcessTrustedWithOptions(kAXTrustedCheckOptionPrompt);
            user_defaults_set("hasRequestedAccessibility", true);
        }
    }
    trusted
}
```

**Key Principles**:
- Only prompt on first launch
- Silent retry on subsequent launches
- Clear error messages if permission denied
- Link to System Settings for manual enabling

---

## ⚡ Performance Optimization

### Response Time Goals

| Operation | Target | Achieved |
|-----------|--------|----------|
| Key event detection | <5ms | ✅ <3ms |
| IME switching | <10ms | ✅ <8ms |
| Settings load | <50ms | ✅ <30ms |
| App startup | <1s | ✅ <500ms |

### Optimization Techniques

1. **Pre-cached Input Sources**
   ```rust
   // Cache input source references at startup
   let alphanumeric = TISInputSource::find_by_id("com.apple.keylayout.ABC");
   let hiragana = TISInputSource::find_by_id("com.apple.inputmethod.Kotoeri.Hiragana");
   ```

2. **Efficient Event Filtering**
   ```rust
   // Only subscribe to relevant event types
   let event_mask = (1 << CGEventType::KeyDown as u64)
       | (1 << CGEventType::FlagsChanged as u64);
   // Ignore mouse events, scroll, etc.
   ```

3. **Minimal Memory Footprint**
   - Rust zero-cost abstractions
   - No garbage collection overhead
   - Static allocation for hot paths

4. **Lazy Settings Loading**
   - Load settings only when UI opened
   - Keep minimal state in event tap
   - Reload only on explicit save

---

## 🧪 Testing Strategy

### Unit Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_key_mapping_serialization() {
        let mapping = KeyMapping {
            input: KeyboardShortcut { keyCode: 55, modifiers: vec![] },
            output: IMEAction::Alphanumeric,
        };
        let json = serde_json::to_string(&mapping).unwrap();
        let deserialized: KeyMapping = serde_json::from_str(&json).unwrap();
        assert_eq!(mapping, deserialized);
    }

    #[test]
    fn test_ime_manager_initialization() {
        let ime = IMEManager::new().unwrap();
        assert!(ime.switch_to_alphanumeric().is_ok());
    }
}
```

### Integration Tests

```rust
#[test]
fn test_settings_persistence() {
    let settings = Settings {
        key_mappings: vec![/* ... */],
        excluded_apps: vec!["Xcode".to_string()],
        launch_at_startup: true,
    };

    settings.save().unwrap();
    let loaded = Settings::load().unwrap();
    assert_eq!(settings, loaded);
}
```

### E2E Tests

- Manual testing on real macOS systems
- Test matrix: macOS 14 (Sonoma) + macOS 15 (Sequoia)
- Hardware: M1/M2/M3/M4 + Intel

---

## 📊 Monitoring & Observability

### Logging

```rust
use tracing::{info, warn, error};

// Structured logging
info!(key_code = 55, "Key pressed");
warn!(app = "Xcode", "App excluded, passing through");
error!(error = %e, "Failed to switch IME");
```

### Metrics (Future)

- Key event processing time (p50, p95, p99)
- IME switch success rate
- Settings load/save latency
- Memory usage tracking

---

## 🔗 External Dependencies

### Rust Crates

```toml
[dependencies]
tauri = "2.8.4"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
core-graphics = "0.23"
core-foundation = "0.9"
cocoa = "0.25"
dirs = "5.0"
tracing = "0.1"
```

### Build Dependencies

```toml
[build-dependencies]
tauri-build = "2.8.4"
```

---

## 🚀 Deployment Architecture

### Bundle Structure

```
⌘IME.app/
├── Contents/
│   ├── Info.plist              # App metadata
│   ├── MacOS/
│   │   └── cmd-ime             # Rust binary
│   ├── Resources/
│   │   ├── icons/              # App icons
│   │   └── assets/             # UI resources
│   └── Frameworks/             # Tauri runtime
```

### Distribution Formats

1. **DMG** (Primary)
   - User-friendly drag-to-Applications
   - Code signed + notarized
   - Size: ~10MB

2. **Homebrew Cask** (Secondary)
   ```bash
   brew install --cask cmd-ime
   ```

3. **Direct Download** (GitHub Releases)
   - Versioned releases
   - Automatic updates (future)

---

## 🔄 Migration from Swift/Cocoa

### Architectural Changes

| Aspect | Swift/Cocoa (v3.1.0) | Rust/Tauri (v3.2.0) |
|--------|---------------------|---------------------|
| **UI Framework** | Storyboards + XIB | HTML/CSS/JS |
| **Event Handling** | NSEvent + CGEvent | CGEvent only (Rust FFI) |
| **Settings** | UserDefaults (plist) | JSON file |
| **Distribution** | Xcode build → DMG | Tauri bundler → DMG |
| **Testing** | XCTest | Cargo test + E2E |

### Migration Strategy

1. **Core First** - Migrate event_tap.rs, ime.rs, settings.rs
2. **UI Second** - Rebuild UI in web technologies
3. **Testing Third** - Validate feature parity
4. **Distribution Fourth** - DMG + Homebrew
5. **Deprecation** - Archive Swift/Cocoa codebase

---

## 🔗 Related Documents

- [VISION.md](./VISION.md) - Why we're building this
- [ROADMAP.md](./ROADMAP.md) - Development timeline
- [CLAUDE.md](./CLAUDE.md) - Development documentation
- [README.md](./README.md) - User guide

---

**"Clean architecture. Efficient code. Transparent behavior."**

— Agiletec Inc.
