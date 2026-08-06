import XCTest
import Carbon.HIToolbox
@testable import CmdIMESwift

/// Spike for the multilingual input-source generalization design (see PR brief):
/// does `TISSelectInputSource` reliably switch *between separate keyboard input
/// sources* (e.g. ABC <-> Pinyin, ABC <-> 2-Set Korean), as opposed to the
/// internal Japanese IME mode toggle (ABC <-> Kana within one IME), which is
/// known to only move the menu-bar indicator without posting Eisu/Kana keys
/// (see `KeyboardShortcut.postEvent()`).
///
/// This test mutates system input-source state: it enables Pinyin / 2-Set
/// Korean if not already present, and disables anything it enabled when done.
/// Skippable so headless CI stays clean.
final class InputSourceSwitchSpikeTests: XCTestCase {

    private let pinyinID = "com.apple.inputmethod.SCIM.ITABC"
    private let koreanID = "com.apple.inputmethod.Korean.2SetKorean"
    private let abcID = "com.apple.keylayout.ABC"

    func testTISSelectSwitchesBetweenSeparateInputSources() throws {
        guard ProcessInfo.processInfo.environment["CMDIME_SPIKE_INPUT_SOURCE_SWITCH"] != nil else {
            throw XCTSkip("set CMDIME_SPIKE_INPUT_SOURCE_SWITCH=1 to run the live TIS switch spike")
        }

        let startID = currentSourceID()
        addTeardownBlock { [self] in
            _ = select(id: abcID)
        }

        dumpAllInstalled(matching: "SCIM")
        dumpAllInstalled(matching: "Korean")

        // Modes (e.g. SCIM.ITABC) belong to a parent input method
        // (TISTypeKeyboardInputMethodModeEnabled, e.g. SCIM) which must itself
        // be enabled before any of its child modes become selectable — the
        // same parent/mode relationship as com.google.inputmethod.Japanese and
        // its .base mode.
        try assertRoundTrip(parentID: "com.apple.inputmethod.SCIM", sourceID: pinyinID, label: "Pinyin (Simplified)")
        try assertRoundTrip(parentID: "com.apple.inputmethod.Korean", sourceID: koreanID, label: "2-Set Korean")

        print("=== spike summary === started at \(startID)")
    }

    /// Enables `sourceID` if needed, selects it, reads back the current source,
    /// switches to ABC, reads back again, and asserts both transitions actually
    /// took effect (not just that `TISSelectInputSource` returned success).
    private func assertRoundTrip(parentID: String, sourceID: String, label: String) throws {
        guard let source = findSource(id: sourceID) else {
            throw XCTSkip("\(label) (\(sourceID)) is not installed on this machine")
        }

        print("[\(label)] category=\(prop(source, kTISPropertyInputSourceCategory) ?? "nil") " +
              "type=\(prop(source, kTISPropertyInputSourceType) ?? "nil") " +
              "isEnableCapable=\(boolProp(source, kTISPropertyInputSourceIsEnableCapable))")

        let parentWasEnabled = findSource(id: parentID).map(isEnabled) ?? true
        if !parentWasEnabled, let parent = findSource(id: parentID) {
            let status = TISEnableInputSource(parent)
            print("[\(label)] TISEnableInputSource(parent \(parentID)) status=\(status)")
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        }
        addTeardownBlock { [self] in
            if !parentWasEnabled, let p = findSource(id: parentID) {
                TISDisableInputSource(p)
            }
        }

        let wasEnabled = isEnabled(source)
        if !wasEnabled {
            let enableStatus = TISEnableInputSource(source)
            print("[\(label)] TISEnableInputSource status=\(enableStatus)")
            // Enabling broadcasts kTISNotifyEnabledKeyboardInputSourcesChanged
            // asynchronously; give the run loop a chance to process it before
            // re-reading the property or attempting to select.
            RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        }
        addTeardownBlock { [self] in
            if !wasEnabled, let s = findSource(id: sourceID) {
                TISDisableInputSource(s)
            }
        }

        if let refreshed = findSource(id: sourceID) {
            print("[\(label)] after enable: enabled=\(isEnabled(refreshed)) selectable=\(selectCapable(refreshed))")
        }

        // ABC -> target
        XCTAssertTrue(select(id: abcID), "failed to select ABC as baseline")
        Thread.sleep(forTimeInterval: 0.3)
        let selectResult = select(id: sourceID)
        Thread.sleep(forTimeInterval: 0.3)
        let afterSelect = currentSourceID()
        print("[\(label)] TISSelectInputSource(\(sourceID)) returned success=\(selectResult); read-back id=\(afterSelect)")
        XCTAssertTrue(selectResult, "\(label): TISSelectInputSource reported failure")
        XCTAssertEqual(afterSelect, sourceID, "\(label): read-back did not move to the target source (stale-select suspected)")

        // target -> ABC
        let backResult = select(id: abcID)
        Thread.sleep(forTimeInterval: 0.3)
        let afterBack = currentSourceID()
        print("[\(label)] TISSelectInputSource(ABC) returned success=\(backResult); read-back id=\(afterBack)")
        XCTAssertTrue(backResult)
        XCTAssertEqual(afterBack, abcID, "\(label): failed to switch back to ABC")
    }

    /// Dumps every installed (enabled or not) source whose id contains
    /// `substring`, to find the parent input method entry for a given mode.
    private func dumpAllInstalled(matching substring: String) {
        guard let list = TISCreateInputSourceList(nil, true)?.takeRetainedValue() else { return }
        let sources = (list as NSArray) as? [TISInputSource] ?? []
        for s in sources {
            guard let id = prop(s, kTISPropertyInputSourceID), id.contains(substring) else { continue }
            print("[installed:\(substring)] id=\(id) category=\(prop(s, kTISPropertyInputSourceCategory) ?? "nil") " +
                  "type=\(prop(s, kTISPropertyInputSourceType) ?? "nil") modeID=\(prop(s, kTISPropertyInputModeID) ?? "nil") " +
                  "enabled=\(boolProp(s, kTISPropertyInputSourceIsEnabled)) enableCapable=\(boolProp(s, kTISPropertyInputSourceIsEnableCapable))")
        }
    }

    // MARK: - TIS helpers

    private func findSource(id: String) -> TISInputSource? {
        let conditions = [kTISPropertyInputSourceID as String: id] as CFDictionary
        guard let list = TISCreateInputSourceList(conditions, true)?.takeRetainedValue() else { return nil }
        let sources = (list as NSArray) as? [TISInputSource] ?? []
        return sources.first
    }

    private func isEnabled(_ source: TISInputSource) -> Bool {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) else { return false }
        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(ptr).takeUnretainedValue())
    }

    private func selectCapable(_ source: TISInputSource) -> Bool {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable) else { return false }
        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(ptr).takeUnretainedValue())
    }

    private func prop(_ s: TISInputSource, _ key: CFString) -> String? {
        guard let p = TISGetInputSourceProperty(s, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(p).takeUnretainedValue() as String
    }

    private func boolProp(_ s: TISInputSource, _ key: CFString) -> Bool {
        guard let p = TISGetInputSourceProperty(s, key) else { return false }
        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(p).takeUnretainedValue())
    }

    @discardableResult
    private func select(id: String) -> Bool {
        guard let source = findSource(id: id) else { return false }
        let status = TISSelectInputSource(source)
        if status != noErr {
            print("TISSelectInputSource(\(id)) OSStatus=\(status)")
        }
        return status == noErr
    }

    private func currentSourceID() -> String {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return "" }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }
}
