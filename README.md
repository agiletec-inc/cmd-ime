# ⌘IME

⌘IME is a small macOS app that lets you switch between alphanumeric and kana input with the left and right Command keys.

Open the app, grant accessibility access once, and use your Command keys to switch input more quickly.

## Quick Start

**Homebrew (recommended)**

```bash
brew install --cask agiletec-inc/tap/cmd-ime
```

**DMG**

1. Download the latest `cmd-ime-<version>.dmg` from [Releases](https://github.com/agiletec-inc/cmd-ime/releases/latest)
2. Open the DMG
3. Drag `CmdIME.app` into `Applications`
4. Launch the app and grant accessibility permissions when prompted

## What It Does

- Left Command switches to alphanumeric input
- Right Command switches to hiragana/kana input
- Fully customizable key mappings — remap any modifier combination to any key
- App exclusion list — disable switching in specific apps
- Auto-restarts when updated via `brew upgrade` (no manual re-launch needed)

## Why Use It

- **Simple & Fast**: Minimal resource usage, instant response
- **Swift-Only Stack**: Native macOS code (no Tauri/Electron)
- **Modern macOS Support**: Built for macOS 13 and later
- **Customizable**: Remap key combinations in Preferences

## Settings

Open the menu bar icon and choose **Preferences** (or press `,`) to access three tabs:

- **General** — Launch at login, menu bar icon visibility, update check settings, version info
- **Shortcuts** — Add, remove, and reorder key mappings
- **Exclusions** — Apps where IME switching is disabled

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon (arm64)

## Building from Source

### Prerequisites
- Swift 5.10+ (Xcode 15 or newer)
- Xcode Command Line Tools

### Build Steps
```bash
git clone https://github.com/agiletec-inc/cmd-ime.git
cd cmd-ime/apps/cmd-ime-swift

# Debug build
swift build

# Release binary
swift build -c release

# Signed .app bundle for local testing
CMDIME_BUILD_MODE=local ./scripts/package.sh
```

For distribution builds, set `CMDIME_SIGNING_IDENTITY` (Developer ID Application) and `CMDIME_SPARKLE_PUBLIC_ED_KEY`. `package.sh` falls back to ad-hoc signing when neither is set.

## Development

See [CLAUDE.md](CLAUDE.md) for detailed development documentation.

## Testing

Run the automated test suites before shipping any change:

```bash
cd apps/cmd-ime-swift
swift test
```

## Uninstall

1. Quit the app (menu bar → ⌘ icon → Quit)
2. Delete `⌘IME.app` from Applications
3. Remove preferences: `defaults delete com.kazuki.cmdime`

---

## 🌟 Part of the AIRIS Ecosystem

⌘IME is part of the **AIRIS Suite** - a collection of self-hosted, privacy-first tools for developers.

### Other AIRIS Tools

| Component | Purpose |
|-----------|---------|
| **[airis-mcp-gateway](https://github.com/agiletec-inc/airis-mcp-gateway)** | 🚪 Unified MCP hub with 90% token reduction |
| **[mindbase](https://github.com/agiletec-inc/mindbase)** | 💾 Local cross-session memory with semantic search |
| **[airis-workspace](https://github.com/agiletec-inc/airis-workspace)** | 🏗️ Docker-first monorepo manager |
| **[neural](https://github.com/agiletec-inc/neural)** | 🌐 Local LLM translation tool (DeepL alternative) |
| **[airis-code](https://github.com/agiletec-inc/airis-code)** | 🖥️ Terminal-first autonomous coding agent |

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
