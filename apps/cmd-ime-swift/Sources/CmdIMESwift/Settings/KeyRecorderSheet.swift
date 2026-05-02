//
//  KeyRecorderSheet.swift
//  ⌘IME
//
//  Modal sheet that captures a single key press (with modifiers) and
//  reports it back as a `KeyboardShortcut`. Uses NSEvent local monitors
//  rather than the global CGEvent tap so the key never leaks to the
//  rest of the system while the user is recording.
//

import SwiftUI
import Cocoa

/// While true, KeyEvent's CGEvent tap leaves keys unmodified so that
/// the recorder sheet captures them without firing the IME switch.
var isRecordingShortcut: Bool = false

struct KeyRecorderSheet: View {
    let title: String
    let allowModifierOnly: Bool
    let initial: KeyboardShortcut
    let onCommit: (KeyboardShortcut) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var captured: KeyboardShortcut

    init(title: String,
         allowModifierOnly: Bool,
         initial: KeyboardShortcut,
         onCommit: @escaping (KeyboardShortcut) -> Void) {
        self.title = title
        self.allowModifierOnly = allowModifierOnly
        self.initial = initial
        self.onCommit = onCommit
        self._captured = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(title).font(.headline)

            Text(captured.toString().isEmpty ? "Press a key…" : captured.toString())
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.textBackgroundColor))
                )

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    onCommit(captured)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(captured.toString().isEmpty)
            }
        }
        .padding(24)
        .frame(width: 360)
        .background(KeyRecorderHost(allowModifierOnly: allowModifierOnly,
                                     captured: $captured))
    }
}

/// Invisible NSView that installs local NSEvent monitors on appear and
/// tears them down on disappear. Reports captured shortcuts via binding.
private struct KeyRecorderHost: NSViewRepresentable {
    let allowModifierOnly: Bool
    @Binding var captured: KeyboardShortcut

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.attach(allowModifierOnly: allowModifierOnly,
                                    binding: $captured)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private var keyMonitor: Any?
        private var flagsMonitor: Any?

        deinit { detach() }

        func attach(allowModifierOnly: Bool, binding: Binding<KeyboardShortcut>) {
            detach()
            isRecordingShortcut = true
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                let shortcut = KeyboardShortcut(
                    keyCode: CGKeyCode(event.keyCode),
                    flags: CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
                )
                binding.wrappedValue = shortcut
                return nil  // swallow the key
            }
            if allowModifierOnly {
                flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
                    let shortcut = KeyboardShortcut(
                        keyCode: CGKeyCode(event.keyCode),
                        flags: CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
                    )
                    binding.wrappedValue = shortcut
                    return event
                }
            }
        }

        func detach() {
            if let monitor = keyMonitor { NSEvent.removeMonitor(monitor) }
            if let monitor = flagsMonitor { NSEvent.removeMonitor(monitor) }
            keyMonitor = nil
            flagsMonitor = nil
            isRecordingShortcut = false
        }
    }
}
