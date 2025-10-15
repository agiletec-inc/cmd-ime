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

## System Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac

## Building from Source

### Prerequisites
- Rust toolchain
- Node.js and pnpm
- Xcode Command Line Tools

### Build Steps
```bash
git clone https://github.com/kazuki/cmd-ime.git
cd cmd-ime/cmd-ime-rust

# Install dependencies
pnpm install

# Development mode with hot reload
pnpm tauri dev

# Build release version
pnpm tauri build

# The .app will be in:
# cmd-ime-rust/src-tauri/target/release/bundle/macos/
```

## Development

See [CLAUDE.md](CLAUDE.md) for detailed development documentation.

## Uninstall

1. Quit the app (menu bar → ⌘ icon → Quit)
2. Delete `⌘IME.app` from Applications
3. Remove preferences: `rm ~/Library/Preferences/com.kazuki.cmd-ime.plist`

## License

MIT License - See [LICENSE](LICENSE) file for details.

Based on the original [cmd-eikana](https://github.com/imasanari/cmd-eikana) project.
