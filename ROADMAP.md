# ⌘IME - Roadmap

**Maintained by**: Agiletec Inc.
**Last Updated**: 2025-10-15

---

## 📍 Current Status

**Phase**: Phase 2 (Rust/Tauri Migration) → In Progress
**Version**: v3.2.0 (Rust/Tauri), v3.1.0 (Swift/Cocoa Legacy)
**Progress**: Core implementation 80%, UI 40%, Testing 20%

---

## 🗺️ Development Phases

### Phase 0: Swift/Cocoa Implementation ✅ **COMPLETE**
**Timeline**: 2024-09 ~ 2025-09 (1 year)
**Status**: ✅ Production-ready (v3.1.0)

#### Goal
Establish functional IME switching tool for macOS with customizable keyboard shortcuts.

#### Deliverables
- ✅ Swift/Cocoa native implementation
- ✅ CGEvent tap for system-wide key monitoring
- ✅ Customizable key mappings UI
- ✅ App exclusion list
- ✅ Login item support
- ✅ DMG distribution
- ✅ Comprehensive test suite

#### Success Criteria
- ✅ Response time: <10ms
- ✅ Memory usage: <50MB
- ✅ macOS 14.0 (Sonoma) compatibility
- ✅ 80%+ code coverage

#### Lessons Learned
- **macOS Sequoia compatibility issues** - LSUIElement + CGEvent tap conflicts
- **Accessibility permission UX** - Need better first-launch experience
- **Mouse drag bug** - Required NSEvent + CGEvent hybrid workaround
- **Maintainability** - Swift/Cocoa aging, hard to maintain

**Decision**: Migrate to Rust/Tauri for modern architecture and long-term maintainability.

---

### Phase 1: Rust/Tauri Migration 🚧 **IN PROGRESS**
**Timeline**: 2025-10 ~ 2025-11 (2 months)
**Status**: 🚧 80% core, 40% UI, 20% testing

#### Goal
Complete migration from Swift/Cocoa to Rust/Tauri while maintaining feature parity.

#### Key Milestones

##### Milestone 1.1: Core Rust Implementation (Week 1-2) ✅ **COMPLETE**
**Target**: 2025-10-14
**Status**: ✅ 100% complete

- ✅ **event_tap.rs** - CGEvent tap implementation
- ✅ **ime.rs** - IME switching logic
- ✅ **settings.rs** - Configuration management
- ✅ **lib.rs** - Tauri command handlers

##### Milestone 1.2: Frontend UI (Week 3-4) 🚧 **IN PROGRESS**
**Target**: 2025-10-28
**Status**: 🚧 40% complete

- [ ] **Main Window** - Settings interface
- [ ] **Key Mapping UI** - Customizable shortcuts
- [ ] **App Exclusion UI** - Exclude specific apps
- [ ] **Menu Bar Integration** - Status icon and quick access
- [ ] **First-launch UX** - Accessibility permission flow

##### Milestone 1.3: Testing & Stability (Week 5-6) 📋 **PLANNED**
**Target**: 2025-11-11
**Status**: 📋 20% complete

- [ ] **Unit Tests** - Core Rust modules
- [ ] **Integration Tests** - Tauri command flows
- [ ] **E2E Tests** - Full app workflow
- [ ] **Performance Testing** - Response time, memory usage
- [ ] **Compatibility Testing** - macOS 14+, M1/M2/M3/M4

##### Milestone 1.4: Distribution (Week 7-8) 📋 **PLANNED**
**Target**: 2025-11-25
**Status**: 📋 Planned

- [ ] **DMG Creation** - Tauri bundler configuration
- [ ] **Code Signing** - Apple Developer certificate
- [ ] **Notarization** - Apple notarization process
- [ ] **Homebrew Cask** - Formula for `brew install`

#### Success Criteria
- [ ] Feature parity with Swift/Cocoa v3.1.0
- [ ] Response time: <10ms (maintained)
- [ ] Memory usage: <50MB (maintained)
- [ ] macOS Sequoia compatibility: ✅
- [ ] Build size: <10MB (Tauri advantage)

#### Value Delivered
- **Modern Architecture**: Rust + Tauri for long-term maintainability
- **Cross-Platform Foundation**: Potential Windows/Linux support
- **Better UX**: Modern web-based UI framework
- **Community**: Easier for contributors (web technologies)

---

### Phase 2: Advanced Customization 📋 **PLANNED**
**Timeline**: 2025-12 ~ 2026-01 (2 months)
**Status**: 📋 Planning

#### Goal
Add advanced customization features beyond basic key mapping.

#### Key Features

##### Feature 2.1: Per-App Shortcuts
- **Problem**: Same shortcuts don't work for all apps
- **Solution**: App-specific key mapping profiles
- **Benefit**: IDE-specific shortcuts without conflicts

##### Feature 2.2: Shortcut Profiles
- **Problem**: Different workflows need different mappings
- **Solution**: Named profiles, quick switching
- **Benefit**: "Coding mode" vs "Writing mode" profiles

##### Feature 2.3: Advanced Mappings
- **Problem**: Simple left/right Command too basic
- **Solution**: Combo keys, sequences, modifiers
- **Benefit**: Power users get full control

##### Feature 2.4: Import/Export
- **Problem**: Can't share configurations across machines
- **Solution**: JSON export/import, sync via cloud
- **Benefit**: Easy team onboarding, backup

#### Success Criteria
- [ ] Per-app shortcuts: 10+ apps configured
- [ ] Profiles: 5+ named profiles created
- [ ] User satisfaction: 90%+ positive feedback

#### Value Delivered
- **Power User Features**: Advanced users get full control
- **Team Collaboration**: Share configurations
- **Flexibility**: Adapt to any workflow

---

### Phase 3: Cross-Platform Support 🔮 **FUTURE**
**Timeline**: 2026-02 ~ 2026-04 (3 months)
**Status**: 🔮 Future planning

#### Goal
Leverage Tauri's cross-platform capabilities to support Windows and Linux.

#### Strategic Initiatives

##### Initiative 3.1: Windows Support
- **Vision**: IME switching for Windows developers
- **Challenges**:
  - Different API (Windows Input Method Manager)
  - Registry-based configuration
  - UAC permissions

##### Initiative 3.2: Linux Support
- **Vision**: IME switching for Linux developers
- **Challenges**:
  - Multiple IME frameworks (iBus, fcitx)
  - X11 vs Wayland
  - Desktop environment variations

##### Initiative 3.3: Unified Configuration
- **Vision**: Same config works across platforms
- **Implementation**:
  - Platform-agnostic key mapping format
  - Platform-specific backend adapters
  - Unified frontend UI

#### Success Criteria
- [ ] Windows: Functional IME switching
- [ ] Linux: Support for iBus + fcitx
- [ ] Unified config: Works on all platforms
- [ ] User base: 10,000+ across platforms

#### Value Delivered
- **Cross-Platform**: One tool for all operating systems
- **Consistency**: Same workflow everywhere
- **Market Expansion**: Reach Windows/Linux developers

---

### Phase 4: Ecosystem & Community 🔮 **FUTURE**
**Timeline**: 2026-05 ~ 2026-12 (8 months)
**Status**: 🔮 Long-term vision

#### Goal
Build a thriving community and plugin ecosystem around ⌘IME.

#### Strategic Initiatives

##### Initiative 4.1: Plugin System
- **Vision**: Extend functionality with community plugins
- **Features**:
  - Plugin API (Rust + TypeScript)
  - Plugin marketplace
  - Auto-update mechanism
  - Sandboxed execution

##### Initiative 4.2: Community Hub
- **Vision**: Central place for documentation, plugins, discussions
- **Components**:
  - Official documentation site
  - Plugin marketplace
  - Community forum
  - Tutorial videos

##### Initiative 4.3: Integration Ecosystem
- **Vision**: Connect with other productivity tools
- **Targets**:
  - IDE integration (VS Code, JetBrains)
  - Automation tools (Raycast, Alfred)
  - Karabiner-Elements compatibility
  - AIRIS MCP Gateway integration

#### Success Criteria
- [ ] Plugins: 50+ community plugins
- [ ] Contributors: 100+ GitHub contributors
- [ ] Stars: 1,000+ GitHub stars
- [ ] Downloads: 50,000+ total downloads

#### Value Delivered
- **Community**: Thriving ecosystem of users and contributors
- **Extensions**: Infinite customization possibilities
- **Integrations**: Works seamlessly with other tools

---

## 🎯 Strategic Milestones Summary

| Phase | Timeline | Goal | Key Metric | Status |
|-------|----------|------|------------|--------|
| **Phase 0** | Sep 2024 - Sep 2025 | Swift/Cocoa Implementation | v3.1.0 shipped | ✅ Complete |
| **Phase 1** | Oct - Nov 2025 | Rust/Tauri Migration | Feature parity | 🚧 80% |
| **Phase 2** | Dec 2025 - Jan 2026 | Advanced Customization | Power user features | 📋 Planned |
| **Phase 3** | Feb - Apr 2026 | Cross-Platform | Windows + Linux | 🔮 Future |
| **Phase 4** | May - Dec 2026 | Ecosystem | Plugin marketplace | 🔮 Vision |

---

## 🔄 Iteration & Feedback Loops

### Phase 1 (Current)
- **Week 1-2**: Core Rust implementation → ✅ Complete
- **Week 3-4**: Frontend UI → 🚧 In progress
- **Week 5-6**: Testing & stability → 📋 Next
- **Week 7-8**: Distribution → 📋 Final

### Phase 2 (Next)
- **Month 1**: Feature development (per-app shortcuts, profiles)
- **Month 2**: Community beta testing and feedback
- **Continuous**: GitHub issues and feature requests

---

## 🚨 Risk Management

### Technical Risks

| Risk | Impact | Mitigation | Status |
|------|--------|------------|--------|
| macOS Sequoia compatibility | High | Test early, adapt quickly | 🚧 Testing |
| Performance regression | Medium | Benchmark against Swift version | 📋 Planned |
| Accessibility permission UX | Medium | Improve first-launch flow | 📋 Planned |
| Tauri bundle size | Low | Optimize dependencies | 📋 Monitor |

### Market Risks

| Risk | Impact | Mitigation | Status |
|------|--------|------------|--------|
| Low adoption | Medium | Focus on developer UX | 🚧 Monitoring |
| Competing solutions | Low | Open source + modern stack | ✅ Advantage |
| macOS API changes | Low | Maintain compatibility layer | 📋 Monitor |

---

## 📊 Success Metrics Tracking

### Phase 0 (Swift/Cocoa - Completed)
- ✅ Implementation: 100% complete
- ✅ Testing: 80% code coverage
- ✅ Distribution: DMG creation working
- ✅ Documentation: Comprehensive

### Phase 1 (Rust/Tauri - Current)
- 🚧 Core implementation: 80% → Target: 100% by Oct 28
- 🚧 Frontend UI: 40% → Target: 100% by Nov 11
- 📋 Testing: 20% → Target: 100% by Nov 25
- 📋 Distribution: 0% → Target: 100% by Nov 30

### Phase 2 (Next)
- 📋 Advanced features: 0% → Target: 100% by Jan 31
- 📋 Community feedback: 0 → Target: 50+ responses

---

## 🔗 Dependencies & Prerequisites

### Phase 0 → Phase 1
**Blockers**: None (Phase 0 complete, Phase 1 in progress)

### Phase 1 → Phase 2
**Prerequisites**:
- Rust/Tauri version feature-complete
- All tests passing
- Stability validated (no crashes, <1% error rate)

### Phase 2 → Phase 3
**Prerequisites**:
- Advanced features validated with 100+ users
- Community feedback integrated
- Codebase refactored for cross-platform

### Phase 3 → Phase 4
**Prerequisites**:
- Windows + Linux support stable
- 1,000+ active users across platforms
- Community established

---

## 💡 Strategic Pivots & Decisions

### Decision Log

**2025-09-15**: Migrate to Rust/Tauri
- **Decision**: Start Phase 1 (Rust/Tauri migration)
- **Rationale**: Swift/Cocoa aging, macOS Sequoia issues, cross-platform potential

**2025-10-15**: Prioritize core features
- **Decision**: Focus on feature parity first, defer advanced features
- **Rationale**: Stable foundation before enhancements

**2025-10-15**: Open source documentation
- **Decision**: Add VISION.md, ROADMAP.md, ARCHITECTURE.md
- **Rationale**: Align with Agiletec Inc. philosophy, attract contributors

---

## 🔗 Related Documents

- [VISION.md](./VISION.md) - Why we're building this
- [ARCHITECTURE.md](./ARCHITECTURE.md) - How it's built
- [CLAUDE.md](./CLAUDE.md) - Development documentation
- [README.md](./README.md) - User-facing documentation

---

**"Build with purpose. Ship with quality. Scale with community."**

— Agiletec Inc.
