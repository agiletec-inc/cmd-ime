import XCTest
@testable import CmdIMESwift

final class KeyMappingTests: XCTestCase {

    func testDictionaryRoundTrip() {
        let mapping = KeyMapping(
            input: KeyboardShortcut(keyCode: 55, flags: .maskCommand),
            output: KeyboardShortcut(keyCode: 102),
            enable: true
        )

        let dictionary = mapping.toDictionary()
        let restored = KeyMapping(dictionary: dictionary)

        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.input.keyCode, 55)
        XCTAssertEqual(restored?.input.flags.rawValue, CGEventFlags.maskCommand.rawValue)
        XCTAssertEqual(restored?.output.keyCode, 102)
        XCTAssertEqual(restored?.enable, true)
    }

    // SwiftUI ForEach must key on a stable per-instance id, never the array
    // index — distinct mappings must never collide, and an id must not change
    // across mutation/persistence round-trips.
    func testEachMappingHasDistinctStableIdentity() {
        let first = KeyMapping()
        let second = KeyMapping()
        XCTAssertNotEqual(first.id, second.id)

        let originalID = first.id
        first.input = KeyboardShortcut(keyCode: 55)
        XCTAssertEqual(first.id, originalID, "Mutating a mapping must not change its identity")

        let restored = KeyMapping(dictionary: first.toDictionary())
        XCTAssertNotNil(restored)
        XCTAssertNotEqual(restored?.id, first.id, "A decoded copy is a new instance with its own id")
    }

    func testInitFailsOnMalformedDictionary() {
        XCTAssertNil(KeyMapping(dictionary: [:]))
        XCTAssertNil(KeyMapping(dictionary: ["input": ["keyCode": 1, "flags": 0]]))  // missing output
        XCTAssertNil(KeyMapping(dictionary: [
            "input": "not a dictionary",
            "output": ["keyCode": 1, "flags": 0],
            "enable": true
        ]))
    }
}
