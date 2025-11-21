import XCTest
@testable import CmdIMESwift

final class KeyEventTests: XCTestCase {
    
    var keyEvent: KeyEvent!
    
    override func setUp() {
        super.setUp()
        keyEvent = KeyEvent()
        // Reset global state
        keyMappingList = []
        shortcutList = [:]
    }
    
    override func tearDown() {
        keyEvent = nil
        keyMappingList = []
        shortcutList = [:]
        super.tearDown()
    }
    
    func testHasConvertedEvent_MatchesMapping() {
        // Setup: Map Command_L (55) to Kana (104)
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 104)
        let mapping = KeyMapping(input: input, output: output)
        
        keyMappingList = [mapping]
        keyMappingListToShortcutList()
        
        // Create event: Command_L down
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        event.flags = .maskCommand
        
        // Verify
        XCTAssertTrue(keyEvent.hasConvertedEvent(event))
    }
    
    func testHasConvertedEvent_NoMatch() {
        // Setup: Map Command_L (55) to Kana (104)
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 104)
        let mapping = KeyMapping(input: input, output: output)
        
        keyMappingList = [mapping]
        keyMappingListToShortcutList()
        
        // Create event: 'A' (0) down
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
        
        // Verify
        XCTAssertFalse(keyEvent.hasConvertedEvent(event))
    }
    
    func testGetConvertedEvent_ReturnsMappedEvent() {
        // Setup: Map Command_L (55) to Kana (104)
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 104)
        let mapping = KeyMapping(input: input, output: output)
        
        keyMappingList = [mapping]
        keyMappingListToShortcutList()
        
        // Create event: Command_L down
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        event.flags = .maskCommand
        
        // Execute
        // We need to call hasConvertedEvent first to set the internal state (hasConvertedEventLog)
        _ = keyEvent.hasConvertedEvent(event)
        let convertedEvent = keyEvent.getConvertedEvent(event)
        
        // Verify
        XCTAssertNotNil(convertedEvent)
        XCTAssertEqual(convertedEvent?.getIntegerValueField(.keyboardEventKeycode), 104)
    }
    
    func testGetConvertedEvent_DisableMapping() {
        // Setup: Map Command_L (55) to Disable (999)
        let input = KeyboardShortcut(keyCode: 55, flags: .maskCommand)
        let output = KeyboardShortcut(keyCode: 999) // 999 is Disable
        let mapping = KeyMapping(input: input, output: output)
        
        keyMappingList = [mapping]
        keyMappingListToShortcutList()
        
        // Create event: Command_L down
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: true)!
        event.flags = .maskCommand
        
        // Execute
        _ = keyEvent.hasConvertedEvent(event)
        let convertedEvent = keyEvent.getConvertedEvent(event)
        
        // Verify: Should return nil for Disable mapping
        XCTAssertNil(convertedEvent)
    }
}
