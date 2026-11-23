import XCTest
@testable import CmdIMEStoreCore

final class InputSourceDefaultsTests: XCTestCase {
    func testInitialAssignmentsChooseABCAndJapaneseKeyboardSource() {
        let sources = [
            StoreInputSource(id: "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese", localizedName: "Japanese", languages: ["ja"]),
            StoreInputSource(id: "com.apple.keylayout.ABC", localizedName: "ABC", languages: ["en"])
        ]

        XCTAssertEqual(
            StoreInputSourceCatalog.initialAssignments(in: sources).left,
            "com.apple.keylayout.ABC"
        )
        XCTAssertEqual(
            StoreInputSourceCatalog.initialAssignments(in: sources).right,
            "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese"
        )
    }

    func testInitialAssignmentsLeaveMissingSourcesUnassigned() {
        let assignments = StoreInputSourceCatalog.initialAssignments(in: [])
        XCTAssertEqual(assignments.left, "")
        XCTAssertEqual(assignments.right, "")
    }

    func testInitialAssignmentsPreferJapaneseKanaNamedSource() {
        let sources = [
            StoreInputSource(id: "jp-romaji", localizedName: "Japanese - Romaji", languages: ["ja"]),
            StoreInputSource(id: "jp-kana", localizedName: "Japanese - Kana", languages: ["ja"])
        ]

        XCTAssertEqual(StoreInputSourceCatalog.initialAssignments(in: sources).right, "jp-kana")
    }
}
