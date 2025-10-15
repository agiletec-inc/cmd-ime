# ⌘IME - Vision

**Maintained by**: Agiletec Inc.
**Created**: 2025-10-15
**License**: MIT

---

## 🎯 Mission Statement

**Developers deserve control over their own tools.**

⌘IME eliminates the fundamental frustration of macOS IME switching by giving developers complete control over keyboard shortcuts. No vendor lock-in. No proprietary formats. No hidden behavior.

We believe productivity tools should be **transparent, customizable, and under developer control**.

---

## 🌍 Problem We're Solving

### Current State (Broken)

```
macOS IME Switching:
  Default: Ctrl+Space or Command+Space
    ↓ Problems
  - Conflicts with IDE shortcuts
  - Slow response time
  - No customization without third-party apps
  - Vendor-controlled behavior

Third-Party Solutions:
  - Proprietary closed-source apps
  - Outdated Swift implementations
  - Poor macOS Sequoia compatibility
  - No modern architecture
```

### Future State (Our Vision)

```
⌘IME:
  - Instant switching with Command keys
  - Full customization via simple UI
  - Open source (MIT) - inspect and modify freely
  - Modern Rust + Tauri architecture
  - macOS Sequoia compatible
  - Zero vendor dependency
```

---

## 🏢 Alignment with Agiletec Inc. Vision

⌘IME is a concrete embodiment of Agiletec Inc.'s corporate philosophy: **"Eliminate dependency structures"** and **"Empower self-sufficiency."**

### Corporate Mission: 多重請負構造を撲滅する

**Traditional productivity tool structure creates vendor dependencies that users must accept.**

```
Traditional Structure (Vendor Dependency):
  Developer
    ↓ Must accept
  macOS default IME behavior
    ↓ Or depend on
  Proprietary third-party app
    ↓ Results in
  Developers lose control over their workflow
```

**This is "vendor lock-in" in the productivity tools domain.**

Just as companies become dependent on multi-layered IT contractors, developers become dependent on tool vendors. They have no choice but to accept the limitations.

**We eliminate this structure:**

```
⌘IME (Developer Control):
  Developer
    ↓ Controls
  Open source tool (self-hosted)
    ↓ Customizes
  Keyboard shortcuts, behavior, source code
    ↓ Results in
  Developers regain control over their environment
```

**Key eliminations**:
- ❌ **Vendor lock-in** → Open source transparency
- ❌ **Proprietary limitations** → Full customization
- ❌ **Hidden behavior** → Inspectable source code
- ❌ **Forced updates** → User-controlled versioning

**All eliminated. Developers control their tools.**

### Corporate Vision: すべての企業に自社開発

**Developer productivity is the foundation of in-house development capability.**

Companies struggle with in-house development often cite:
- "Our developers waste time fighting tools"
- "Environment setup is too complex"
- "Productivity tools don't work as expected"

**These are not excuses—they are real structural problems.**

⌘IME addresses the root cause at the individual developer level:

1. **Complexity → Simplicity**
   - One command install
   - Works immediately
   - No configuration required (unless desired)

2. **Vendor dependency → Self-sufficiency**
   - Open source (MIT)
   - Modify and redistribute freely
   - No hidden behavior or telemetry

3. **Tool friction → Seamless workflow**
   - Instant IME switching
   - No conflicts with IDE shortcuts
   - Customizable to individual preferences

**Result**: Developers can focus on creating value, not fighting their environment.

### From Personal Tools to Team Productivity

**Fixing developer tools is not just about individual productivity—it's about enabling organizational capability.**

```
Inefficient Tools
  → Developers waste mental energy
  → Teams struggle with productivity
  → Companies think "development is too complex"
  → Outsourcing becomes the default
  → In-house capability disappears

Efficient Tools (⌘IME)
  → Developers work efficiently
  → Teams maintain high productivity
  → Companies see "development is manageable"
  → In-house development becomes feasible
  → Self-sufficiency grows
```

**⌘IME is one piece of the productivity puzzle.**

By solving IME switching friction, we remove one barrier that makes developers less productive. Combined with other tools (AIRIS MCP Gateway, Focus), we build a complete productive environment.

---

## 💡 Core Philosophy

### 1. Developer Control
**"Developers should control their own tools, not be controlled by them."**

Traditional: Accept vendor defaults
⌘IME: Customize everything, inspect everything, modify everything

### 2. Open Source by Default
**"Productivity tools should be transparent and community-driven."**

No black boxes. No proprietary formats.
MIT License → Free to use, modify, and redistribute.

### 3. Modern Architecture
**"Use the best technology for the job, regardless of legacy."**

Swift/Cocoa → Legacy (macOS only, aging codebase)
Rust/Tauri → Modern (cross-platform foundation, performant, maintainable)

### 4. Zero Friction
**"Tools should disappear into the workflow."**

Instant response (<10ms).
No conflicts with existing shortcuts.
Works immediately without configuration.

---

## 🚀 Strategic Value

### For Individual Developers
- **Speed**: Instant IME switching = zero mental overhead
- **Control**: Customize shortcuts to personal preference
- **Trust**: Open source = no telemetry, no vendor tracking

### For Teams
- **Consistency**: Same tool across all team members
- **Customization**: Team-specific keyboard layouts supported
- **Reliability**: Stable, tested, community-maintained

### For Open Source Community
- **MIT License**: Free to use and modify
- **Modern Stack**: Learn from Rust/Tauri implementation
- **Reference Implementation**: Best practices for macOS automation

---

## 🎓 Technical Innovation

### Rust + Tauri Architecture

**Why migrate from Swift/Cocoa to Rust/Tauri?**

| Aspect | Swift/Cocoa (Legacy) | Rust/Tauri (Modern) |
|--------|---------------------|---------------------|
| **Platform** | macOS only | Cross-platform foundation |
| **Performance** | Native Objective-C | Native Rust (zero-cost abstractions) |
| **Maintainability** | Aging codebase | Modern, safe code |
| **UI Framework** | Storyboards | Web-based (HTML/CSS/JS) |
| **Distribution** | DMG manual install | Multiple formats (DMG, pkg, Homebrew) |
| **Compatibility** | macOS Sequoia issues | Modern API usage |

**Rust advantages**:
- Memory safety without garbage collection
- Zero-cost abstractions
- Fearless concurrency
- Strong type system

**Tauri advantages**:
- Modern UI development (web technologies)
- Cross-platform foundation
- Small bundle size
- Active community

### Key Event Handling

**Core Challenge**: System-wide keyboard event monitoring without interfering with other apps.

**Implementation**:
```rust
// event_tap.rs - CGEvent tap for key interception
pub fn create_event_tap() -> Result<CFMachPort, Error> {
    // Monitor Command key events system-wide
    // Convert to IME switching based on user mappings
    // Pass through to system if not handled
}
```

**Architecture**:
1. **CGEvent tap** - Low-level keyboard monitoring
2. **Event filtering** - Only capture relevant keys
3. **IME switching** - Native macOS Text Input Source API
4. **Configuration** - Tauri commands for frontend-backend communication

---

## 🌟 Long-Term Vision

### Phase 1: macOS Excellence (Current)
**Goal**: Best-in-class IME switching for macOS developers
**Target**: 1,000 active users

### Phase 2: Advanced Customization (2025 Q2)
**Goal**: Per-app shortcuts, advanced mappings, profiles
**Target**: 5,000 active users

### Phase 3: Cross-Platform Foundation (2025 Q3)
**Goal**: Windows and Linux support (Tauri advantage)
**Target**: 10,000 active users

### Phase 4: Ecosystem (2025 Q4)
**Goal**: Plugin system, community extensions
**Target**: Recommended by developer communities

---

## 🧭 Guiding Principles

1. **User First**: Developer experience over implementation complexity
2. **Simplicity**: Zero configuration by default, infinite customization when needed
3. **Performance**: Sub-10ms response time, always
4. **Transparency**: Open source, no telemetry, no hidden behavior
5. **Reliability**: Stable, tested, production-ready
6. **Community**: MIT license, welcoming to contributors
7. **Quality**: Clean code, comprehensive documentation

---

## 📐 Success Metrics

### Technical Goals
- ✅ Response time: <10ms
- ✅ Memory usage: <50MB
- ✅ CPU usage: <1% idle
- ✅ Compatibility: macOS 14+ (Sonoma, Sequoia)

### Adoption Goals
- Phase 1: 1,000 developers (macOS excellence)
- Phase 2: 5,000 developers (advanced features)
- Phase 3: 10,000 developers (cross-platform)

### Community Goals
- 50+ contributors
- 100+ GitHub stars
- Documentation in Japanese + English

---

## 💬 Why This Matters

**macOS IME switching is a daily friction point for bilingual developers.**

Switching between English and Japanese dozens of times per hour adds mental overhead. The default shortcuts conflict with IDE shortcuts. Third-party tools are proprietary or outdated.

**We're fixing this at the foundation level.**

⌘IME is not just another IME switcher—it's a **reference implementation of developer-controlled productivity tools**. By proving this can be done well in the open source community, we're establishing a pattern for other productivity tools.

**This is bigger than one utility.**

⌘IME is part of Agiletec Inc.'s mission to eliminate dependency structures. By building transparent, customizable, community-driven tools, we're showing that developers don't need to accept vendor limitations.

---

## 🔗 Related Documents

### Corporate Level
- [Agiletec Inc. VISION.md](https://github.com/agiletec-inc/agiletec/blob/main/VISION.md) - Corporate philosophy and mission

### Product Level
- [ROADMAP.md](./ROADMAP.md) - Development phases and timeline
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical design and implementation
- [CLAUDE.md](./CLAUDE.md) - Development documentation
- [README.md](./README.md) - Installation and usage guide

---

**"Control your tools. Control your workflow. Control your future."**

— Agiletec Inc.
