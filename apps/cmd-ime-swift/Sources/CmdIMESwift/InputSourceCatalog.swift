//
//  InputSourceCatalog.swift
//  ⌘IME
//
//  Enumerates and selects installed keyboard input sources for the
//  multilingual key-mapping action (Settings > Shortcuts). This is a
//  distinct mechanism from the Eisu/Kana key-post in
//  `KeyboardShortcut.postEvent()`: that one drives the Japanese IME's
//  internal mode by synthesizing keystrokes, because bare
//  `TISSelectInputSource` only moves the menu-bar indicator for it. Every
//  other language's mapping (ABC <-> Pinyin, ABC <-> 2-Set Korean, ...) is a
//  switch between *separate* input sources, where `TISSelectInputSource`
//  works directly — confirmed live by InputSourceSwitchSpikeTests.
//

import Carbon.HIToolbox
import Foundation

enum InputSourceCatalog {
    struct Entry: Identifiable, Equatable {
        let id: String
        let localizedName: String
    }

    /// Installed (enabled or not) selectable keyboard input sources —
    /// standalone layouts (e.g. ABC) and IME modes (e.g. Google Japanese's
    /// `.base`, SCIM's `.ITABC`). Filtering by category + select-capable
    /// naturally excludes both the parent input-method entries (not
    /// select-capable themselves, only their modes are) and palette sources
    /// (Character Viewer, emoji, etc. sit in a different category — a known
    /// contamination risk when enumerating "enabled sources" naively).
    static func selectableKeyboardSources() -> [Entry] {
        let conditions = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as Any,
            kTISPropertyInputSourceIsSelectCapable as String: true
        ] as CFDictionary
        guard let list = TISCreateInputSourceList(conditions, true)?.takeRetainedValue() else { return [] }
        let sources = (list as NSArray) as? [TISInputSource] ?? []
        return sources.compactMap { source -> Entry? in
            guard let id = stringProperty(source, kTISPropertyInputSourceID) else { return nil }
            let name = stringProperty(source, kTISPropertyLocalizedName) ?? id
            return Entry(id: id, localizedName: name)
        }
        .sorted { $0.localizedName < $1.localizedName }
    }

    /// Enables `id`'s parent input method (if it has one) and `id` itself
    /// when needed, then selects it. A mode's parent is not enabled
    /// automatically by enabling the mode — see InputSourceSwitchSpikeTests,
    /// which found this the hard way for SCIM.ITABC / Korean.2SetKorean.
    /// Returns false if `id` isn't installed or the select call fails.
    @discardableResult
    static func select(id: String) -> Bool {
        guard let source = find(id: id) else { return false }

        if let parentID = parentCandidateID(for: id),
           let parent = find(id: parentID), !isEnabled(parent) {
            TISEnableInputSource(parent)
        }
        if !isEnabled(source) {
            TISEnableInputSource(source)
        }
        return TISSelectInputSource(source) == noErr
    }

    /// A mode id's parent input method id is conventionally its id with the
    /// last dot-separated component dropped (`com.apple.inputmethod.SCIM.ITABC`
    /// -> `com.apple.inputmethod.SCIM`, `com.google.inputmethod.Japanese.base`
    /// -> `com.google.inputmethod.Japanese`). `kTISPropertyInputModeID` isn't
    /// reliable for this: it can equal the mode's own id (SCIM.ITABC) instead
    /// of the parent's. Standalone layouts (`com.apple.keylayout.ABC`) yield a
    /// candidate that resolves to no installed source, which is correct — they
    /// have no parent to enable.
    static func parentCandidateID(for id: String) -> String? {
        guard let lastDot = id.lastIndex(of: ".") else { return nil }
        return String(id[..<lastDot])
    }

    // MARK: - TIS helpers

    private static func find(id: String) -> TISInputSource? {
        let conditions = [kTISPropertyInputSourceID as String: id] as CFDictionary
        guard let list = TISCreateInputSourceList(conditions, true)?.takeRetainedValue() else { return nil }
        let sources = (list as NSArray) as? [TISInputSource] ?? []
        return sources.first
    }

    private static func isEnabled(_ source: TISInputSource) -> Bool {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) else { return false }
        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(ptr).takeUnretainedValue())
    }

    private static func stringProperty(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }
}
