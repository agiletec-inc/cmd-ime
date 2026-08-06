//
//  Localization.swift
//  ⌘IME
//
//  Single entry point for every user-facing string. SPM never merges a
//  target's resources into `Bundle.main` (unlike an Xcode app target), so a
//  bundle-less `Text("...")`/`NSLocalizedString` lookup would silently
//  return the raw key in a real .app build. This resolves explicitly against
//  `Bundle.module`, and returns a plain `String` rather than a
//  `LocalizedStringKey` so SwiftUI displays it verbatim instead of
//  re-resolving it against `Bundle.main` a second time — the same reason
//  callers must use the `StringProtocol` overloads of `Text`/`Toggle`/
//  `Button`/`Picker`/`Label` (not the `LocalizedStringKey` ones) when passing
//  the result. Works identically under `swift build`/`swift test` and Xcode,
//  since it's a plain runtime `String(localized:)` call, not dependent on
//  Xcode's String Catalog symbol-generation build phase.
//

import Foundation

/// Looks up `key` in `Localizable.xcstrings` for the current locale. `key` is
/// a stable catalog identifier (e.g. "general.launchAtLogin"), not the
/// English display text, so English wording can change without touching
/// every other locale's key.
func L(_ key: String) -> String {
    String(localized: String.LocalizationValue(key), bundle: .module)
}
