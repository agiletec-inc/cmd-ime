# ⌘IME

A lightweight macOS app that switches between alphanumeric and kana input when tapping left/right Command keys.

Built with Rust + Tauri for modern macOS.

## Features

- **Simple & Fast**: Minimal resource usage, instant response
- **Modern Stack**: Rust backend + Tauri frontend
- **M4 Mac Optimized**: Native arm64 build for Apple Silicon
- **macOS 14+ Support**: Built for modern macOS versions
- **Customizable**: Remap any key combination via preferences

## Installation

### Homebrew (Coming Soon)
```bash
brew install --cask cmd-ime
```

### Manual Installation
1. Download the latest release from [Releases](https://github.com/kazuki/cmd-ime/releases)
2. Move `⌘IME.app` to Applications folder
3. Right-click and select "Open" (first time only)
4. Grant accessibility permissions when prompted

## Usage

- **Left Command (⌘)**: Switch to Alphanumeric
- **Right Command (⌘)**: Switch to Hiragana/Kana

Customize key mappings in Preferences (⌘ icon in menu bar → Preferences).

### Login Item
- Toggle "ログイン時に開く" from the menu bar or preferences to add/remove a LaunchAgent (`~/Library/LaunchAgents/com.kazuki.cmdime.launcher.plist`) so the app starts at login.

### Updates
- Toggle "起動時にアップデートを確認" to query GitHub Releases on launch, or press "確認する" in Preferences → 設定 to manually check and open the latest release page.

## System Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac

## Building from Source

### Prerequisites
- Rust toolchain
- Swift 5.10+ (Xcode 15 or newer)
- Xcode Command Line Tools

### Build Steps
```bash
git clone https://github.com/agiletec-inc/cmd-ime.git
cd cmd-ime

# 1. Build the Rust backend (generates libcmd_ime_rust_lib.a)
cargo build --release --manifest-path apps/cmd-ime-rust/src-tauri/Cargo.toml

# 2. Build the Swift menu bar app (and bundle it)
cd apps/cmd-ime-swift
swift build -c release
./scripts/package.sh

# The .app bundle will be generated at:
# apps/cmd-ime-swift/.build/release/CmdIME.app
```

## Development

See [CLAUDE.md](CLAUDE.md) for detailed development documentation.

## Testing

Run the automated test suites before shipping any change:

```bash
# 1. Rust backend (unit tests + clippy lint pass)
cargo test --manifest-path apps/cmd-ime-rust/src-tauri/Cargo.toml
cargo clippy --manifest-path apps/cmd-ime-rust/src-tauri/Cargo.toml

# 2. Swift menu bar app + CmdIME runtime bridge
cd apps/cmd-ime-swift
swift test

# 3. Tauri frontend smoke tests (requires pnpm install in apps/cmd-ime-rust)
cd ../cmd-ime-rust
pnpm install
pnpm test
```

Rust settings tests respect the `CMD_IME_CONFIG_DIR` environment variable so they never touch your real `~/.config/cmd-ime` files.

## Uninstall

1. Quit the app (menu bar → ⌘ icon → Quit)
2. Delete `⌘IME.app` from Applications
3. Remove preferences: `rm ~/Library/Preferences/com.kazuki.cmd-ime.plist`

## License

MIT License - See [LICENSE](LICENSE) file for details.

Based on the original [cmd-eikana](https://github.com/imasanari/cmd-eikana) project.
