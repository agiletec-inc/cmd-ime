//
//  KeyMapping.swift
//  ⌘IME
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

class KeyMapping: NSObject, Identifiable {
    // Stable per-instance identity for SwiftUI ForEach — must not be derived
    // from array position, which desyncs row state on add/remove/reorder.
    let id = UUID()
    var input: KeyboardShortcut
    var output: KeyboardShortcut
    var enable: Bool
    // Non-nil selects this TIS input source id via InputSourceCatalog.select(id:)
    // instead of posting `output` as a key (see KeyEvent.modifierKeyUp). Mutually
    // exclusive with a key-post output — set by updateKeyMappingOutputSource(at:)
    // and cleared whenever a key-based output is chosen again.
    var outputInputSourceID: String?

    init(input: KeyboardShortcut, output: KeyboardShortcut, enable: Bool = true, outputInputSourceID: String? = nil) {
        self.input = input
        self.output = output
        self.enable = enable
        self.outputInputSourceID = outputInputSourceID

        super.init()
    }

    override init() {
        input = KeyboardShortcut()
        output = KeyboardShortcut()
        self.enable = true
        self.outputInputSourceID = nil
        super.init()
    }

    init?(dictionary: [AnyHashable: Any]) {
        if let inputKeyDic = dictionary["input"] as? [AnyHashable: Any],
            let inputKey = KeyboardShortcut(dictionary: inputKeyDic),
            let outputKeyDic = dictionary["output"] as? [AnyHashable: Any],
            let outputKey = KeyboardShortcut(dictionary: outputKeyDic),
            let enable = dictionary["enable"] as? Bool {

            self.input = inputKey
            self.output = outputKey
            self.enable = enable
            // Absent in dictionaries persisted before this field existed.
            self.outputInputSourceID = dictionary["outputInputSourceID"] as? String

            super.init()
        } else {
            return nil
        }
    }

    func toDictionary() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [
            "input": input.toDictionary(),
            "output": output.toDictionary(),
            "enable": enable
        ]
        dictionary["outputInputSourceID"] = outputInputSourceID
        return dictionary
    }
}
