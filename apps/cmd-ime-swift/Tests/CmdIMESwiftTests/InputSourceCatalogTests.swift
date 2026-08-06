import XCTest
@testable import CmdIMESwift

final class InputSourceCatalogTests: XCTestCase {

    // MARK: - parentCandidateID (pure string logic, no TIS involved)

    func testParentCandidateID_DropsLastDotComponent_ForAppleModeID() {
        XCTAssertEqual(
            InputSourceCatalog.parentCandidateID(for: "com.apple.inputmethod.SCIM.ITABC"),
            "com.apple.inputmethod.SCIM"
        )
    }

    func testParentCandidateID_DropsLastDotComponent_ForVendorModeID() {
        // Confirmed against the real TIS dump: com.google.inputmethod.Japanese.base's
        // parent entry is com.google.inputmethod.Japanese, not the modeID property
        // value (com.apple.inputmethod.Japanese), which is unreliable for this.
        XCTAssertEqual(
            InputSourceCatalog.parentCandidateID(for: "com.google.inputmethod.Japanese.base"),
            "com.google.inputmethod.Japanese"
        )
    }

    func testParentCandidateID_NilForIDWithoutADot() {
        XCTAssertNil(InputSourceCatalog.parentCandidateID(for: "noDotsHere"))
    }

    // MARK: - selectableKeyboardSources (live, read-only enumeration —
    // TISCreateInputSourceList needs no special entitlement to read, unlike
    // TISEnableInputSource/TISSelectInputSource which mutate system state and
    // are only exercised by the gated InputSourceSwitchSpikeTests).

    func testSelectableKeyboardSources_IncludesABC() {
        let sources = InputSourceCatalog.selectableKeyboardSources()

        XCTAssertTrue(sources.contains { $0.id == "com.apple.keylayout.ABC" },
                      "com.apple.keylayout.ABC ships on every macOS install")
    }

    func testSelectableKeyboardSources_ExcludesPaletteSources() {
        // Known contamination risk (see CLAUDE.md): Character Viewer / emoji
        // palettes share the "enabled sources" list but must not appear as
        // switchable input-source actions.
        let sources = InputSourceCatalog.selectableKeyboardSources()

        XCTAssertFalse(sources.contains { $0.id.contains("CharacterPalette") })
        XCTAssertFalse(sources.contains { $0.id == "com.apple.PressAndHold" })
    }

    func testSelectableKeyboardSources_HasNoDuplicateIDs() {
        let sources = InputSourceCatalog.selectableKeyboardSources()
        let ids = sources.map(\.id)

        XCTAssertEqual(ids.count, Set(ids).count)
    }
}
