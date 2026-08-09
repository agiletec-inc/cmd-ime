//
//  ExclusionsSettingsView.swift
//  ⌘IME
//
//  Manages the list of apps in which ⌘IME's key remapping is suppressed.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExclusionsSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var recentApps: [AppData] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("exclusions.description"))
                .font(.callout)
                .foregroundStyle(.secondary)

            sectionHeader(L("exclusions.excludedHeader"))
            if settings.exclusionApps.isEmpty {
                emptyRow(L("exclusions.emptyExcluded"))
            } else {
                List {
                    ForEach(settings.exclusionApps) { app in
                        HStack {
                            appIcon(for: app)
                            VStack(alignment: .leading) {
                                Text(app.name)
                                Text(app.id).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                if let index = settings.exclusionApps.firstIndex(where: { $0.id == app.id }) {
                                    settings.removeExclusion(at: index)
                                    reloadRecent()
                                }
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .frame(minHeight: 100)
            }

            HStack {
                sectionHeader(L("exclusions.recentHeader"))
                Spacer()
                Button(L("exclusions.addAppButton")) { browseForApp() }
                    .buttonStyle(.borderless)
                    .font(.callout)
                    .help(Text(L("exclusions.addAppHelp")))
            }
            if recentApps.isEmpty {
                emptyRow(L("exclusions.emptyRecent"))
            } else {
                List {
                    ForEach(recentApps, id: \.id) { app in
                        HStack {
                            appIcon(for: app)
                            VStack(alignment: .leading) {
                                Text(app.name)
                                Text(app.id).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                settings.addExclusion(app)
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                            .buttonStyle(.borderless)
                            .disabled(settings.exclusionApps.contains(where: { $0.id == app.id }))
                        }
                    }
                }
                .frame(minHeight: 100)
            }
        }
        .onAppear { reloadRecent() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            reloadRecent()
        }
    }

    private func browseForApp() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType(filenameExtension: "app") ?? .data]
        panel.message = L("exclusions.openPanelMessage")
        panel.prompt = L("exclusions.openPanelPrompt")
        if panel.runModal() == .OK {
            for url in panel.urls {
                guard let bundle = Bundle(url: url),
                      let id = bundle.bundleIdentifier else { continue }
                let name = (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
                    ?? (bundle.infoDictionary?["CFBundleName"] as? String)
                    ?? url.deletingPathExtension().lastPathComponent
                settings.addExclusion(AppData(name: name, id: id))
            }
            reloadRecent()
        }
    }

    private func reloadRecent() {
        let excludedIDs = Set(settings.exclusionApps.map { $0.id })
        recentApps = activeAppsList.filter { !excludedIDs.contains($0.id) }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.top, 4)
    }

    @ViewBuilder
    private func emptyRow(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
    }

    @ViewBuilder
    private func appIcon(for app: AppData) -> some View {
        if let nsImage = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.id)
            .map({ NSWorkspace.shared.icon(forFile: $0.path) }) {
            Image(nsImage: nsImage)
                .resizable()
                .frame(width: 24, height: 24)
        } else {
            Image(systemName: "app")
                .frame(width: 24, height: 24)
        }
    }
}
