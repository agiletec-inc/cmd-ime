//
//  InputSourceSwitcher.swift
//  ⌘IME
//

import Cocoa
import Carbon.HIToolbox

/// Switches the system input source directly via the TIS (Text Input Sources)
/// API, used as a fallback for apps that mishandle synthesized Eisu/Kana keys.
///
/// The default IME-switch mechanism is posting the Eisu (102) / Kana (104)
/// virtual keys: those drive the IME's *internal* input mode (Hiragana vs.
/// direct/Roman), which is the only thing that works for single-mode IMEs like
/// Google Japanese Input and ATOK — they expose one "base" input mode to TIS
/// and toggle Hiragana/direct internally, so `TISSelectInputSource` can move
/// the menu-bar indicator without actually changing what gets typed.
///
/// A few apps (e.g. Affinity) run their own text engine and never route the
/// synthesized Eisu/Kana key through the standard input-context machinery, so
/// the injected key leaks as a literal (a half-width space) instead of
/// switching IME. For those apps only, we switch via TIS instead — accepting
/// that on a single-mode IME this changes the source but not the internal
/// mode, which is still better than injecting garbage.
enum InputSourceSwitcher {
    static let eisuKeyCode: CGKeyCode = 102
    static let kanaKeyCode: CGKeyCode = 104

    /// Frontmost-app bundle IDs whose text engine mishandles synthesized
    /// Eisu/Kana keys, so cmd-ime must switch via TIS instead of posting them.
    static let tisSwitchAppBundleIDs: Set<String> = [
        "com.canva.affinity",              // Affinity (unified v2.6+)
        "com.seriflabs.affinitydesigner2",
        "com.seriflabs.affinityphoto2",
        "com.seriflabs.affinitypublisher2"
    ]

    /// Whether the given remap *output* keyCode is an IME input-source switch
    /// (Eisu or Kana). Pure function so the decision is unit-testable without
    /// touching the (non-thread-safe, GUI-session-dependent) TIS API.
    static func isInputSourceSwitchKey(outputKeyCode: CGKeyCode) -> Bool {
        outputKeyCode == eisuKeyCode || outputKeyCode == kanaKeyCode
    }

    /// Performs the actual input-source switch for an Eisu/Kana output keyCode.
    /// No-op for any other keyCode.
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

    /// Finds an enabled keyboard input source whose languages include "ja",
    /// preferring the standard Hiragana input mode
    /// (`com.apple.inputmethod.Japanese`) when more than one is enabled.
    ///
    /// Internal (not private) so the regression test can assert the picked
    /// source is a keyboard input source, never a palette.
    static func japaneseInputSource() -> TISInputSource? {
        // Restrict to the keyboard category: language "ja" alone also matches
        // palette input sources (e.g. the 50-on Kana Palette), and selecting
        // one of those opens a floating palette window instead of switching
        // the IME (v2.4.7 regression).
        let conditions = [
            kTISPropertyInputSourceIsEnabled as String: true,
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String
        ] as CFDictionary
        guard let cfList = TISCreateInputSourceList(conditions, false)?.takeRetainedValue() else {
            return nil
        }
        let sources = (cfList as NSArray) as? [TISInputSource] ?? []

        let japaneseSources = sources.filter { source in
            guard isSelectCapable(source), let languages = inputSourceLanguages(source) else { return false }
            return languages.contains("ja")
        }

        // Prefer the Hiragana input mode; its *mode* ID is
        // "com.apple.inputmethod.Japanese" while the input source ID carries
        // an IME-specific prefix (e.g. "…Kotoeri.RomajiTyping.Japanese"), so
        // match on the mode ID.
        if let hiragana = japaneseSources.first(where: { inputModeID($0) == "com.apple.inputmethod.Japanese" }) {
            return hiragana
        }

        return japaneseSources.first
    }

    private static func inputModeID(_ source: TISInputSource) -> String? {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputModeID) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }

    private static func isSelectCapable(_ source: TISInputSource) -> Bool {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable) else { return false }
        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(ptr).takeUnretainedValue())
    }

    private static func inputSourceLanguages(_ source: TISInputSource) -> [String]? {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else { return nil }
        return Unmanaged<CFArray>.fromOpaque(ptr).takeUnretainedValue() as NSArray as? [String]
    }
}
