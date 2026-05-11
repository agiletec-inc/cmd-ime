//
//  KeyMappings.swift
//  ⌘IME
//
//  Globals consumed by KeyEvent's CGEvent tap. Writes go through
//  AppSettings; KeyEvent reads from these caches in its hot path.
//

import Cocoa

var keyMappingList: [KeyMapping] = []
var shortcutList: [CGKeyCode: [KeyMapping]] = [:]

func keyMappingListToShortcutList() {
    var rebuilt: [CGKeyCode: [KeyMapping]] = [:]
    for mapping in keyMappingList {
        rebuilt[mapping.input.keyCode, default: []].append(mapping)
    }
    shortcutList = rebuilt
}
