//
//  SettingsView.swift
//  ⌘IME
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    enum Tab: String, Hashable, CaseIterable {
        case general
        case shortcuts
        case exclusions

        var label: String {
            switch self {
            case .general: return "General"
            case .shortcuts: return "Shortcuts"
            case .exclusions: return "Exclusions"
            }
        }

        var systemImage: String {
            switch self {
            case .general: return "gearshape"
            case .shortcuts: return "keyboard"
            case .exclusions: return "minus.circle"
            }
        }
    }

    @State private var selection: Tab = .general

    var body: some View {
        TabView(selection: $selection) {
            GeneralSettingsView()
                .tabItem { Label(Tab.general.label, systemImage: Tab.general.systemImage) }
                .tag(Tab.general)

            ShortcutsSettingsView()
                .tabItem { Label(Tab.shortcuts.label, systemImage: Tab.shortcuts.systemImage) }
                .tag(Tab.shortcuts)

            ExclusionsSettingsView()
                .tabItem { Label(Tab.exclusions.label, systemImage: Tab.exclusions.systemImage) }
                .tag(Tab.exclusions)
        }
        .frame(minWidth: 520, minHeight: 360)
        .padding(20)
    }
}
