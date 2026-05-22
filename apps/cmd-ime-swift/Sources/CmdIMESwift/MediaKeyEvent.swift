//
//  MediaKeyEvent.swift
//  ⌘IME
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

class MediaKeyEvent: NSObject {
    let event: CGEvent

    var keyCode: Int
    var flags: CGEventFlags
    var keyDown: Bool

    init?(_ event: CGEvent) {
        if event.type.rawValue != UInt32(NX_SYSDEFINED) {
            return nil
        }

        guard let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype.rawValue == 8 else {
            return nil
        }

        self.event = event
        keyCode = (nsEvent.data1 & 0xffff0000) >> 16
        flags = event.flags
        keyDown = ((nsEvent.data1 & 0xff00) >> 8) == 0xa

        super.init()
    }
}
