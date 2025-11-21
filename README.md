# ⌘IME

A lightweight macOS app that switches between alphanumeric and kana input when tapping left/right Command keys.

Built with Swift for modern macOS.

## Features

- **Simple & Fast**: Minimal resource usage, instant response
- **Swift-Only Stack**: Native macOS code (no Tauri/Electron)
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
- Swift 5.10+ (Xcode 15 or newer)
- Xcode Command Line Tools

### Build Steps
```bash
git clone https://github.com/agiletec-inc/cmd-ime.git
cd cmd-ime

# Build the Swift menu bar app (bundle via Xcode or swift build)
cd apps/cmd-ime-swift
swift build -c release
open CmdIMESwift.xcodeproj   # if you prefer GUI build
```

## Development

See [CLAUDE.md](CLAUDE.md) for detailed development documentation.

## Testing

Run the automated test suites before shipping any change:

```bash
# Swift menu bar app + CmdIME runtime tests
cd apps/cmd-ime-swift
swift test

# Xcode scheme (UI tests & unit tests)
xcodebuild -scheme CmdIMESwift -destination 'platform=macOS,arch=arm64' -skipPackagePluginValidation test
```

## Uninstall

1. Quit the app (menu bar → ⌘ icon → Quit)
2. Delete `⌘IME.app` from Applications
3. Remove preferences: `rm ~/Library/Preferences/com.kazuki.cmd-ime.plist`

---

## 🌟 Part of the AIRIS Ecosystem

⌘IME is part of the **AIRIS Suite** - a collection of self-hosted, privacy-first tools for developers.

### Other AIRIS Tools

| Component | Purpose |
|-----------|---------|
| **[airis-mcp-gateway](https://github.com/agiletec-inc/airis-mcp-gateway)** | 🚪 Unified MCP hub with 90% token reduction |
| **[mindbase](https://github.com/agiletec-inc/mindbase)** | 💾 Local cross-session memory with semantic search |
| **[airis-agent](https://github.com/agiletec-inc/airis-agent)** | 🧠 Intelligence layer for AI coding |
| **[airis-workspace](https://github.com/agiletec-inc/airis-workspace)** | 🏗️ Docker-first monorepo manager |
| **[neural](https://github.com/agiletec-inc/neural)** | 🌐 Local LLM translation tool (DeepL alternative) |
| **[airiscode](https://github.com/agiletec-inc/airiscode)** | 🖥️ Terminal-first autonomous coding agent |

---

## 💖 Support This Project

If you find ⌘IME helpful, consider supporting its development:

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?style=for-the-badge&logo=buy-me-a-coffee)](https://buymeacoffee.com/kazukinakai)
[![GitHub Sponsors](https://img.shields.io/badge/GitHub%20Sponsors-sponsor-pink?style=for-the-badge&logo=github)](https://github.com/sponsors/kazukinakai)

Your support helps maintain and improve all AIRIS projects!

---

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

MIT License - See [LICENSE](LICENSE) file for details.

Based on the original [cmd-eikana](https://github.com/imasanari/cmd-eikana) project.

---

**Built with ❤️ by the [Agiletec](https://github.com/agiletec-inc) team**

**[Agiletec Inc.](https://github.com/agiletec-inc)** | **[Issues](https://github.com/agiletec-inc/cmd-ime/issues)** | **[Discussions](https://github.com/agiletec-inc/cmd-ime/discussions)**
