//
//  ShortcutsSettingsView.swift
//  ⌘IME
//

import SwiftUI

struct ShortcutsSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var inputEditing: InputEdit?
    @State private var customOutputEditing: CustomOutputEdit?

    private struct InputEdit: Identifiable {
        let id = UUID()
        let index: Int
    }
    private struct CustomOutputEdit: Identifiable {
        let id = UUID()
        let index: Int
    }

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

    // Preset output options shown in the dropdown.
    private static let outputPresets: [(label: String, shortcut: KeyboardShortcut)] = [
        ("英数  (Alphanumeric)", KeyboardShortcut(keyCode: 102)),
        ("かな  (Kana)", KeyboardShortcut(keyCode: 104)),
        ("無効  (Disable key)", KeyboardShortcut(keyCode: 999)),
    ]

    var body: some View {
        VStack(spacing: 8) {
            Text("Input: choose from the preset menu or record a custom key. Output: choose from the preset menu.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            List {
                HStack(spacing: 12) {
                    Text("Input")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 120, alignment: .leading)
                        .padding(.horizontal, 8)
                    Spacer().frame(width: 16)
                    Text("Output")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 120, alignment: .leading)
                        .padding(.horizontal, 8)
                    Spacer()
                }
                .padding(.vertical, 2)

                ForEach(Array(settings.keyMappings.enumerated()), id: \.offset) { index, mapping in
                    HStack(spacing: 12) {
                        inputCell(label: mapping.input.toString(), index: index)
                        Image(systemName: "arrow.right").foregroundStyle(.secondary)
                        outputCell(shortcut: mapping.output, index: index)
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
        .sheet(item: $inputEditing) { edit in
            KeyRecorderSheet(
                title: "Record Input",
                allowModifierOnly: true,
                initial: settings.keyMappings[edit.index].input,
                onCommit: { settings.updateKeyMapping(at: edit.index, input: $0) }
            )
        }
        .sheet(item: $customOutputEditing) { edit in
            KeyRecorderSheet(
                title: "Record Custom Output",
                allowModifierOnly: false,
                initial: settings.keyMappings[edit.index].output,
                onCommit: { settings.updateKeyMapping(at: edit.index, output: $0) }
            )
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
            Divider()
            Button("Record custom key…") {
                inputEditing = InputEdit(index: index)
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
        .help("Choose an input key")
    }

    @ViewBuilder
    private func outputCell(shortcut: KeyboardShortcut, index: Int) -> some View {
        Menu {
            ForEach(Self.outputPresets, id: \.label) { preset in
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
            Divider()
            Button("Custom key…") {
                customOutputEditing = CustomOutputEdit(index: index)
            }
        } label: {
            HStack(spacing: 6) {
                Text(shortcut.toString().isEmpty ? "Output" : shortcut.toString())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(shortcut.toString().isEmpty ? Color.secondary : Color.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .cellStyle()
        }
        .menuStyle(.borderlessButton)
        .help("Choose an output key")
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
