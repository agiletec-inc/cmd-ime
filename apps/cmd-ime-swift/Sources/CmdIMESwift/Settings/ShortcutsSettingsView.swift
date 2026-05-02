//
//  ShortcutsSettingsView.swift
//  ⌘IME
//

import SwiftUI

struct ShortcutsSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedRowID: UUID?
    @State private var rowEditing: RowEdit?

    private struct RowEdit: Identifiable {
        let id = UUID()
        let index: Int
        let field: Field
        enum Field { case input, output }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Tap a row to record a new key. Modifier-only inputs (e.g. left ⌘) are allowed for Input.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            List {
                ForEach(Array(settings.keyMappings.enumerated()), id: \.offset) { index, mapping in
                    HStack(spacing: 12) {
                        recordingCell(label: mapping.input.toString(),
                                       placeholder: "Input",
                                       index: index,
                                       field: .input)
                        Image(systemName: "arrow.right").foregroundStyle(.secondary)
                        recordingCell(label: mapping.output.toString(),
                                       placeholder: "Output",
                                       index: index,
                                       field: .output)
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
        .sheet(item: $rowEditing) { edit in
            KeyRecorderSheet(
                title: edit.field == .input ? "Record Input" : "Record Output",
                allowModifierOnly: edit.field == .input,
                initial: edit.field == .input
                    ? settings.keyMappings[edit.index].input
                    : settings.keyMappings[edit.index].output,
                onCommit: { shortcut in
                    if edit.field == .input {
                        settings.updateKeyMapping(at: edit.index, input: shortcut)
                    } else {
                        settings.updateKeyMapping(at: edit.index, output: shortcut)
                    }
                }
            )
        }
    }

    @ViewBuilder
    private func recordingCell(label: String, placeholder: String, index: Int, field: RowEdit.Field) -> some View {
        Button {
            rowEditing = RowEdit(index: index, field: field)
        } label: {
            Text(label.isEmpty ? placeholder : label)
                .frame(minWidth: 100, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
                .foregroundStyle(label.isEmpty ? Color.secondary : Color.primary)
        }
        .buttonStyle(.plain)
    }
}
