//
//  ShortcutsSettingsView.swift
//  ⌘IME
//

import SwiftUI

struct ShortcutsSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    // Common input keys — includes IME-only keys that can't be recorded on English keyboards.
    private static let inputPresets: [(label: String, shortcut: KeyboardShortcut)] = [
        ("Left ⌘  (Left Command)", KeyboardShortcut(keyCode: 55)),
        ("Right ⌘  (Right Command)", KeyboardShortcut(keyCode: 54)),
        ("英数  (Eisu / Alphanumeric)", KeyboardShortcut(keyCode: 102)),
        ("かな  (Kana)", KeyboardShortcut(keyCode: 104)),
        ("⇪  (Caps Lock)", KeyboardShortcut(keyCode: 57)),
        ("Left ⇧  (Left Shift)", KeyboardShortcut(keyCode: 56)),
        ("Right ⇧  (Right Shift)", KeyboardShortcut(keyCode: 60)),
        ("Left ⌥  (Left Option)", KeyboardShortcut(keyCode: 58)),
        ("Right ⌥  (Right Option)", KeyboardShortcut(keyCode: 61)),
        ("Left ⌃  (Left Control)", KeyboardShortcut(keyCode: 59)),
        ("Right ⌃  (Right Control)", KeyboardShortcut(keyCode: 62)),
    ]

    private static let actionPresets: [(label: String, shortcut: KeyboardShortcut)] = [
        ("Switch to Alphanumeric", KeyboardShortcut(keyCode: 102)),
        ("Switch to Kana", KeyboardShortcut(keyCode: 104)),
        ("Disable key", KeyboardShortcut(keyCode: 999)),
    ]

    var body: some View {
        VStack(spacing: 8) {
            Text("Key: the hotkey to intercept. Action: what happens when you press it.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            List {
                HStack(spacing: 12) {
                    Text("Key")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 120, alignment: .leading)
                        .padding(.horizontal, 8)
                    Spacer().frame(width: 16)
                    Text("Action")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 120, alignment: .leading)
                        .padding(.horizontal, 8)
                    Spacer()
                }
                .padding(.vertical, 2)

                ForEach(settings.keyMappings) { mapping in
                    if let index = settings.keyMappings.firstIndex(where: { $0.id == mapping.id }) {
                        HStack(spacing: 12) {
                            inputCell(label: mapping.input.toString(), index: index)
                            Image(systemName: "arrow.right").foregroundStyle(.secondary)
                            actionCell(shortcut: mapping.output, index: index)
                            if Self.isShadowed(settings.keyMappings, at: index) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                                    .help("Shadowed by an earlier mapping with the same input")
                            }
                            Spacer()
                            Button(role: .destructive) {
                                settings.removeKeyMapping(at: index)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                            .help("Remove this mapping")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(minHeight: 200)

            HStack {
                Button {
                    settings.addKeyMapping()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func inputCell(label: String, index: Int) -> some View {
        Menu {
            ForEach(Self.inputPresets, id: \.label) { preset in
                Button {
                    settings.updateKeyMapping(at: index, input: preset.shortcut)
                } label: {
                    if label == preset.shortcut.toString() {
                        Label(preset.label, systemImage: "checkmark")
                    } else {
                        Text(preset.label)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(label.isEmpty ? "Input" : label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(label.isEmpty ? Color.secondary : Color.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .cellStyle()
        }
        .menuStyle(.borderlessButton)
        .help("Choose the hotkey to intercept")
    }

    @ViewBuilder
    private func actionCell(shortcut: KeyboardShortcut, index: Int) -> some View {
        Menu {
            ForEach(Self.actionPresets, id: \.label) { preset in
                Button {
                    settings.updateKeyMapping(at: index, output: preset.shortcut)
                } label: {
                    if shortcut.keyCode == preset.shortcut.keyCode {
                        Label(preset.label, systemImage: "checkmark")
                    } else {
                        Text(preset.label)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(actionLabel(for: shortcut))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(shortcut.keyCode == 0 ? Color.secondary : Color.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .cellStyle()
        }
        .menuStyle(.borderlessButton)
        .help("Choose what happens when this key is pressed")
    }

    private func actionLabel(for shortcut: KeyboardShortcut) -> String {
        Self.actionPresets.first(where: { $0.shortcut.keyCode == shortcut.keyCode })?.label
            ?? (shortcut.toString().isEmpty ? "Action" : shortcut.toString())
    }

    /// True when `mappings[index]` is enabled and an earlier enabled row has
    /// the exact same input (keyCode + flags), so `findMapping`'s
    /// first-match-wins lookup can never reach this row.
    static func isShadowed(_ mappings: [KeyMapping], at index: Int) -> Bool {
        guard mappings.indices.contains(index), mappings[index].enable else { return false }
        let current = mappings[index].input
        return mappings[..<index].contains { earlier in
            earlier.enable
                && earlier.input.keyCode == current.keyCode
                && earlier.input.flags.rawValue == current.flags.rawValue
        }
    }
}

private extension View {
    func cellStyle() -> some View {
        self
            .frame(minWidth: 120, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.textBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor), lineWidth: 1))
            .contentShape(Rectangle())
    }
}
