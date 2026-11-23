import AppKit
import CmdIMEStoreCore
import Combine
import CoreGraphics
import Foundation

@MainActor
final class StoreAppModel: ObservableObject {
    @Published private(set) var inputSources: [StoreInputSource] = []
    @Published private(set) var listenPermissionGranted = CGPreflightListenEventAccess()
    @Published private(set) var isListening = false
    @Published private(set) var statusMessage = String(localized: "status.notListening")

    @Published var leftSourceID: String {
        didSet { UserDefaults.standard.set(leftSourceID, forKey: Self.leftSourceKey) }
    }
    @Published var rightSourceID: String {
        didSet { UserDefaults.standard.set(rightSourceID, forKey: Self.rightSourceKey) }
    }

    private static let leftSourceKey = "store.leftCommandInputSourceID"
    private static let rightSourceKey = "store.rightCommandInputSourceID"
    private var eventTap: CommandEventTap?
    private var wakeSubscription: AnyCancellable?

    init() {
        let savedLeft = UserDefaults.standard.object(forKey: Self.leftSourceKey) as? String
        let savedRight = UserDefaults.standard.object(forKey: Self.rightSourceKey) as? String
        let initialSources = StoreInputSourceCatalog.enabledKeyboardSources()
        let defaults = StoreInputSourceCatalog.initialAssignments(in: initialSources)
        leftSourceID = savedLeft ?? defaults.left
        rightSourceID = savedRight ?? defaults.right
        if savedLeft == nil, !defaults.left.isEmpty {
            UserDefaults.standard.set(defaults.left, forKey: Self.leftSourceKey)
        }
        if savedRight == nil, !defaults.right.isEmpty {
            UserDefaults.standard.set(defaults.right, forKey: Self.rightSourceKey)
        }
        wakeSubscription = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in self?.recoverAfterWake() }
            }
        inputSources = initialSources
        listenPermissionGranted = CGPreflightListenEventAccess()
    }

    func refreshInputSources() {
        inputSources = StoreInputSourceCatalog.enabledKeyboardSources()
        listenPermissionGranted = CGPreflightListenEventAccess()
        if UserDefaults.standard.object(forKey: Self.leftSourceKey) == nil {
            let defaults = StoreInputSourceCatalog.initialAssignments(in: inputSources)
            if !defaults.left.isEmpty { leftSourceID = defaults.left }
        }
        if UserDefaults.standard.object(forKey: Self.rightSourceKey) == nil {
            let defaults = StoreInputSourceCatalog.initialAssignments(in: inputSources)
            if !defaults.right.isEmpty { rightSourceID = defaults.right }
        }
    }

    func requestPermissionAndStart() {
        let tap = CommandEventTap { [weak self] side in
            Task { @MainActor in self?.handleTap(side) }
        }
        eventTap = tap
        switch tap.requestAccessAndStart() {
        case .started:
            isListening = true
            listenPermissionGranted = true
            statusMessage = String(localized: "status.listening")
        case .permissionRequired:
            isListening = false
            listenPermissionGranted = false
            statusMessage = String(localized: "status.permissionRequired")
        case .eventTapUnavailable:
            isListening = false
            listenPermissionGranted = CGPreflightListenEventAccess()
            statusMessage = String(localized: "status.tapUnavailable")
        }
    }

    func recoverAfterWake() {
        guard isListening else { return }
        switch eventTap?.start() {
        case .started:
            statusMessage = String(localized: "status.listening")
        case .permissionRequired:
            isListening = false
            listenPermissionGranted = false
            statusMessage = String(localized: "status.permissionRequired")
        case .eventTapUnavailable, .none:
            isListening = false
            statusMessage = String(localized: "status.tapUnavailable")
        }
    }

    func refreshPermissionState() {
        listenPermissionGranted = CGPreflightListenEventAccess()
        if listenPermissionGranted && !isListening {
            statusMessage = String(localized: "status.permissionGrantedStartAgain")
        }
    }

    func stopListening() {
        eventTap?.stop()
        eventTap = nil
        isListening = false
        statusMessage = String(localized: "status.notListening")
    }

    func openInputMonitoringSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func handleTap(_ side: CommandSide) {
        let sourceID = side == .left ? leftSourceID : rightSourceID
        guard !sourceID.isEmpty else { return }
        switch StoreInputSourceCatalog.select(id: sourceID) {
        case .selected:
            statusMessage = String(localized: "status.sourceSelected")
        case .unavailable:
            statusMessage = String(localized: "status.sourceUnavailable")
            refreshInputSources()
        case .selectFailed:
            statusMessage = String(localized: "status.sourceSelectionFailed")
        case .readbackMismatch:
            statusMessage = String(localized: "status.sourceReadbackMismatch")
        }
    }
}
