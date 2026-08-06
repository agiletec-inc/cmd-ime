//
//  ShortcutsSettingsView.swift
//  ⌘IME
//

import SwiftUI

struct ShortcutsSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    // Common input keys — includes IME-only keys that can't be recorded on English keyboards.
    private static let inputPresets: [(label: String, shortcut: KeyboardShortcut)] = [
        (L("shortcuts.presetLeftCommand"), KeyboardShortcut(keyCode: 55)),
        (L("shortcuts.presetRightCommand"), KeyboardShortcut(keyCode: 54)),
        (L("shortcuts.presetEisu"), KeyboardShortcut(keyCode: 102)),
        (L("shortcuts.presetKana"), KeyboardShortcut(keyCode: 104)),
        (L("shortcuts.presetCapsLock"), KeyboardShortcut(keyCode: 57)),
        (L("shortcuts.presetLeftShift"), KeyboardShortcut(keyCode: 56)),
        (L("shortcuts.presetRightShift"), KeyboardShortcut(keyCode: 60)),
        (L("shortcuts.presetLeftOption"), KeyboardShortcut(keyCode: 58)),
        (L("shortcuts.presetRightOption"), KeyboardShortcut(keyCode: 61)),
        (L("shortcuts.presetLeftControl"), KeyboardShortcut(keyCode: 59)),
        (L("shortcuts.presetRightControl"), KeyboardShortcut(keyCode: 62)),
    ]

    private static let actionPresets: [(label: String, shortcut: KeyboardShortcut)] = [
        (L("shortcuts.actionSwitchToAlphanumeric"), KeyboardShortcut(keyCode: 102)),
        (L("shortcuts.actionSwitchToKana"), KeyboardShortcut(keyCode: 104)),
        (L("shortcuts.actionDisableKey"), KeyboardShortcut(keyCode: 999)),
    ]

    var body: some View {
        VStack(spacing: 8) {
            Text(L("shortcuts.description"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            List {
                HStack(spacing: 12) {
                    Text(L("shortcuts.keyColumnHeader"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 120, alignment: .leading)
                        .padding(.horizontal, 8)
                    Spacer().frame(width: 16)
                    Text(L("shortcuts.actionColumnHeader"))
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
                                    .help(Text(L("shortcuts.shadowedHelp")))
                            }
                            Spacer()
                            Button(role: .destructive) {
                                settings.removeKeyMapping(at: index)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                            .help(Text(L("shortcuts.removeHelp")))
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
                    Label(L("shortcuts.addButton"), systemImage: "plus")
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
                Text(label.isEmpty ? L("shortcuts.inputPlaceholder") : label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(label.isEmpty ? Color.secondary : Color.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .cellStyle()
        }
        .menuStyle(.borderlessButton)
        .help(Text(L("shortcuts.inputHelp")))
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
        .help(Text(L("shortcuts.actionHelp")))
    }

    private func actionLabel(for shortcut: KeyboardShortcut) -> String {
        Self.actionPresets.first(where: { $0.shortcut.keyCode == shortcut.keyCode })?.label
            ?? (shortcut.toString().isEmpty ? L("shortcuts.actionColumnHeader") : shortcut.toString())
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
