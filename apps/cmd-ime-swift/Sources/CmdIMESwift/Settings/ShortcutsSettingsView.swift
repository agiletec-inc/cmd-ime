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
        VStack(spacing: 8) {
            Text("Input accepts modifier-only keys (e.g. left ⌘). Click a cell to record a new key.")
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
            HStack(spacing: 6) {
                Text(label.isEmpty ? placeholder : label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(label.isEmpty ? Color.secondary : Color.primary)
                Image(systemName: "square.and.pencil")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(minWidth: 120, alignment: .leading)
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("\(placeholder): click to record a new key")
    }
}
