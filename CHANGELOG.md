# Changelog

All notable changes to ⌘IME will be documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Version bumps are derived from [Conventional Commits](https://www.conventionalcommits.org/)
on the `main` branch via `.github/workflows/release.yml`.

## [Unreleased]

### Added
- Issue templates (`bug_report.yml`, `feature_request.yml`) and a Discussions
  link in the issue chooser.
- This `CHANGELOG.md`.

### Changed
- Update check now queries the GitHub Releases API instead of the
  decommissioned `ei-kana.appspot.com` endpoint.
- README: align macOS minimum (13.0) with `Package.swift` and `Info.plist`,
  fix Releases URL owner, drop references to a non-existent Xcode project,
  describe Login Item / Updates UI in English.

### Removed
- `apps/cmd-ime-swift/scripts/build_app.sh` — host-specific dead script that
  pulled a Storyboard from one developer's machine.

## [1.2.5] - 2026-05-01

### Changed
- Switch Homebrew cask publish workflow to GitHub App authentication so
  releases no longer depend on a personal access token that expires.

## [1.2.0] - 2025-11-27

### Added
- Initial Swift Package Manager project under `apps/cmd-ime-swift/`.
- `SMAppService.mainApp`-based "Launch at login" implementation
  (`toggleLaunchAtStartup.swift`).
- Code signing in `scripts/package.sh` (ad-hoc).

### Changed
- Renamed the app from `⌘英かな` to `⌘IME`.
- Cleaned up repository structure.

[Unreleased]: https://github.com/agiletec-inc/cmd-ime/compare/v1.2.5...HEAD
[1.2.5]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.2.5
[1.2.0]: https://github.com/agiletec-inc/cmd-ime/releases/tag/v1.2.0
