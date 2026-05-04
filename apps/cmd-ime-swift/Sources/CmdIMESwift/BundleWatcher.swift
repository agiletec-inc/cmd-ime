import Foundation

/// Watches the running app's main executable. Fires `onReplace` on the main
/// queue when the binary is deleted or renamed — which is what `brew upgrade`
/// does (it mv-replaces the .app bundle). The DispatchSource self-invalidates
/// after the event; the caller is expected to restart the process so that
/// Bundle.main re-reads the new Info.plist and Mach-O image.
final class BundleWatcher {
    private var source: DispatchSourceFileSystemObject?

    func start(onReplace: @escaping () -> Void) {
        guard let path = Bundle.main.executablePath else { return }
        start(watching: path, onReplace: onReplace)
    }

    func start(watching path: String, onReplace: @escaping () -> Void) {
        stop()
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.delete, .rename, .write],
            queue: .main
        )
        src.setEventHandler { onReplace() }
        src.setCancelHandler { close(fd) }
        src.resume()
        source = src
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    deinit { stop() }
}
