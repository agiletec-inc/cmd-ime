import XCTest
import Carbon.HIToolbox
@testable import CmdIMESwift

/// Diagnostic dump of the machine's enabled input sources. Not an assertion —
/// run with `swift test --filter InputSourceDumpTests` to see the real TIS
/// structure of the installed IMEs (Google, Kotoeri, …) while debugging the
/// kana-switch behavior. Keep it skippable so CI on headless runners is clean.
final class InputSourceDumpTests: XCTestCase {

    func testDumpEnabledInputSources() throws {
        guard ProcessInfo.processInfo.environment["CMDIME_DUMP_INPUT_SOURCES"] != nil else {
            throw XCTSkip("set CMDIME_DUMP_INPUT_SOURCES=1 to run the diagnostic dump")
        }

        let conditions = [kTISPropertyInputSourceIsEnabled as String: true] as CFDictionary
        let list = TISCreateInputSourceList(conditions, false)!.takeRetainedValue()
        let sources = (list as NSArray) as? [TISInputSource] ?? []

        print("=== enabled input sources (\(sources.count)) ===")
        for s in sources {
            let id = str(s, kTISPropertyInputSourceID)
            let modeID = str(s, kTISPropertyInputModeID)
            let category = str(s, kTISPropertyInputSourceCategory)
            let type = str(s, kTISPropertyInputSourceType)
            let langs = strings(s, kTISPropertyInputSourceLanguages)
            let selectable = bool(s, kTISPropertyInputSourceIsSelectCapable)
            let selected = bool(s, kTISPropertyInputSourceIsSelected)
            print("""
            ---
            id:        \(id ?? "nil")
            modeID:    \(modeID ?? "nil")
            category:  \(shortCat(category))
            type:      \(shortType(type))
            langs:     \(langs ?? [])
            selectable:\(selectable) selected:\(selected)
            """)
        }
    }

    private func str(_ s: TISInputSource, _ key: CFString) -> String? {
        guard let p = TISGetInputSourceProperty(s, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(p).takeUnretainedValue() as String
    }
    private func strings(_ s: TISInputSource, _ key: CFString) -> [String]? {
        guard let p = TISGetInputSourceProperty(s, key) else { return nil }
        return (Unmanaged<CFArray>.fromOpaque(p).takeUnretainedValue() as NSArray) as? [String]
    }
    private func bool(_ s: TISInputSource, _ key: CFString) -> Bool {
        guard let p = TISGetInputSourceProperty(s, key) else { return false }
        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(p).takeUnretainedValue())
    }
    private func shortCat(_ c: String?) -> String {
        (c ?? "nil").replacingOccurrences(of: "TISCategory", with: "")
    }
    private func shortType(_ t: String?) -> String {
        (t ?? "nil").replacingOccurrences(of: "TISType", with: "")
    }
}
