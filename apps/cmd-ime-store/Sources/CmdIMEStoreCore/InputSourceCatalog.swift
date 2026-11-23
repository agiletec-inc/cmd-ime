import Carbon.HIToolbox
import CoreFoundation
import Foundation

public struct StoreInputSource: Identifiable, Equatable, Sendable {
    public let id: String
    public let localizedName: String
    public let languages: [String]

    public init(id: String, localizedName: String, languages: [String] = []) {
        self.id = id
        self.localizedName = localizedName
        self.languages = languages
    }
}

public enum InputSourceSelectionResult: Equatable, Sendable {
    case selected
    case unavailable
    case selectFailed(OSStatus)
    case readbackMismatch
}

public enum StoreInputSourceCatalog {
    /// Lists enabled, selectable keyboard sources; palette sources such as
    /// Emoji & Symbols are excluded by the keyboard-category filter.
    public static func enabledKeyboardSources() -> [StoreInputSource] {
        let conditions: CFDictionary = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as Any,
            kTISPropertyInputSourceIsSelectCapable as String: true
        ] as CFDictionary
        guard let list = TISCreateInputSourceList(conditions, false)?.takeRetainedValue() else {
            return []
        }
        let sources = (list as NSArray) as? [TISInputSource] ?? []
        return sources.compactMap { source in
            guard isEnabled(source),
                  let id = stringProperty(source, kTISPropertyInputSourceID)
            else { return nil }
            return StoreInputSource(
                id: id,
                localizedName: stringProperty(source, kTISPropertyLocalizedName) ?? id,
                languages: stringArrayProperty(source, kTISPropertyInputSourceLanguages)
            )
        }
        .sorted { $0.localizedName.localizedStandardCompare($1.localizedName) == .orderedAscending }
    }

    /// Confirms TIS state after selection. This does not claim text composition
    /// works for a given IME; that still needs real-machine acceptance testing.
    @discardableResult
    public static func select(id: String) -> InputSourceSelectionResult {
        guard let source = find(id: id) else { return .unavailable }
        let status = TISSelectInputSource(source)
        guard status == noErr else { return .selectFailed(status) }
        guard let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              stringProperty(current, kTISPropertyInputSourceID) == id
        else { return .readbackMismatch }
        return .selected
    }

    private static func find(id: String) -> TISInputSource? {
        let conditions: CFDictionary = [kTISPropertyInputSourceID as String: id] as CFDictionary
        guard let list = TISCreateInputSourceList(conditions, false)?.takeRetainedValue() else {
            return nil
        }
        return ((list as NSArray) as? [TISInputSource])?.first
    }

    public static func initialAssignments(in sources: [StoreInputSource]) -> (left: String, right: String) {
        let left = sources.first(where: { $0.id == "com.apple.keylayout.ABC" })?.id ?? ""
        let japanese = sources.filter { $0.id != "com.apple.keylayout.ABC" && $0.languages.contains("ja") }
        let right = japanese.first(where: { $0.localizedName.localizedCaseInsensitiveContains("kana") || $0.localizedName.contains("かな") })?.id
            ?? japanese.first?.id
            ?? ""
        return (left, right)
    }

    private static func stringArrayProperty(_ source: TISInputSource, _ key: CFString) -> [String] {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return [] }
        return (Unmanaged<CFArray>.fromOpaque(ptr).takeUnretainedValue() as NSArray) as? [String] ?? []
    }

    private static func isEnabled(_ source: TISInputSource) -> Bool {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) else {
            return false
        }
        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(ptr).takeUnretainedValue())
    }

    private static func stringProperty(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }
}
