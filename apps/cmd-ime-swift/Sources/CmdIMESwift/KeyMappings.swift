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

func saveKeyMappings() {
    UserDefaults.standard.set(keyMappingList.map { $0.toDictionary() },
                               forKey: AppSettings.Keys.keyMappings)
}

func keyMappingListToShortcutList() {
    var rebuilt: [CGKeyCode: [KeyMapping]] = [:]
    for mapping in keyMappingList {
        rebuilt[mapping.input.keyCode, default: []].append(mapping)
    }
    shortcutList = rebuilt
}
