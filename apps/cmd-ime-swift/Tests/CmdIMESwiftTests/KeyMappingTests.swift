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
