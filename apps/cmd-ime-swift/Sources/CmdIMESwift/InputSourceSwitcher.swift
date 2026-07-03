//
//  InputSourceSwitcher.swift
//  ⌘IME
//

import Cocoa
import Carbon.HIToolbox

/// Switches the system input source directly via the TIS (Text Input Sources)
/// API instead of synthesizing Eisu/Kana key events with `CGEvent.post`.
///
/// Background: some apps (e.g. Affinity) implement their own text engine and
/// never route synthesized Eisu (102) / Kana (104) key events through the
/// standard macOS input-context machinery, so the injected key is consumed as
/// a literal (half-width space) instead of switching IME. Calling TIS
/// directly changes the input source regardless of how the frontmost app
/// handles key events.
enum InputSourceSwitcher {
    static let eisuKeyCode: CGKeyCode = 102
    static let kanaKeyCode: CGKeyCode = 104

    /// Whether the given remap *output* keyCode should be handled by switching
    /// the input source via TIS instead of posting a synthesized key event.
    /// Pulled out as a pure function so the decision is unit-testable without
    /// touching the (non-thread-safe, GUI-session-dependent) TIS API.
    static func shouldSwitchViaTIS(outputKeyCode: CGKeyCode) -> Bool {
        outputKeyCode == eisuKeyCode || outputKeyCode == kanaKeyCode
    }

    /// Performs the actual input-source switch for a remap output keyCode
    /// that satisfies `shouldSwitchViaTIS`. No-op for any other keyCode.
    ///
    /// TIS is not documented as thread-safe, but this is always invoked from
    /// the CGEvent tap callback, which runs on the main run loop (the tap's
    /// run loop source is added to `CFRunLoopGetMain()` in
    /// `KeyEvent.setupCGEventTap()`), so there is no concurrent access.
    static func switchInputSource(outputKeyCode: CGKeyCode) {
        switch outputKeyCode {
        case eisuKeyCode:
            switchToASCIICapable()
        case kanaKeyCode:
            switchToKana()
        default:
            break
        }
    }

    private static func switchToASCIICapable() {
        guard let source = TISCopyCurrentASCIICapableKeyboardInputSource()?.takeRetainedValue() else {
            NSLog("⌘IME: TISCopyCurrentASCIICapableKeyboardInputSource returned nil.")
            return
        }

        let status = TISSelectInputSource(source)
        if status != noErr {
            NSLog("⌘IME: TISSelectInputSource (ASCII-capable) failed with status %d.", status)
        }
    }

    private static func switchToKana() {
        guard let source = japaneseInputSource() else {
            // Never silently break the keystroke — just leave the input
            // source untouched and log why.
            NSLog("⌘IME: no enabled Japanese input source found; ignoring kana switch.")
            return
        }

        let status = TISSelectInputSource(source)
        if status != noErr {
            NSLog("⌘IME: TISSelectInputSource (Japanese) failed with status %d.", status)
        }
    }

    /// Finds an enabled input source whose languages include "ja", preferring
    /// the standard Hiragana input mode (`com.apple.inputmethod.Japanese`)
    /// when more than one Japanese source is enabled.
    private static func japaneseInputSource() -> TISInputSource? {
        let conditions = [kTISPropertyInputSourceIsEnabled as String: true] as CFDictionary
        guard let cfList = TISCreateInputSourceList(conditions, false)?.takeRetainedValue() else {
            return nil
        }
        let sources = (cfList as NSArray) as? [TISInputSource] ?? []

        let japaneseSources = sources.filter { source in
            guard let languages = inputSourceLanguages(source) else { return false }
            return languages.contains("ja")
        }

        if let hiragana = japaneseSources.first(where: { inputSourceID($0) == "com.apple.inputmethod.Japanese" }) {
            return hiragana
        }

        return japaneseSources.first
    }

    private static func inputSourceID(_ source: TISInputSource) -> String? {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }

    private static func inputSourceLanguages(_ source: TISInputSource) -> [String]? {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else { return nil }
        return Unmanaged<CFArray>.fromOpaque(ptr).takeUnretainedValue() as NSArray as? [String]
    }
}
