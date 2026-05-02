import XCTest
@testable import CmdIMESwift

final class BundleWatcherTests: XCTestCase {

    private func makeTempFile() -> String {
        let dir = NSTemporaryDirectory()
        let path = (dir as NSString).appendingPathComponent("BundleWatcher-\(UUID().uuidString).bin")
        FileManager.default.createFile(atPath: path, contents: Data("seed".utf8))
        return path
    }

    func testCallbackFiredOnFileDelete() {
        let path = makeTempFile()
        let watcher = BundleWatcher()
        let expectation = XCTestExpectation(description: "callback fires on delete")

        watcher.start(watching: path) {
            expectation.fulfill()
        }

        // Simulate `brew upgrade` mv-replacing the bundle by deleting the file.
        try? FileManager.default.removeItem(atPath: path)

        wait(for: [expectation], timeout: 2.0)
        watcher.stop()
    }

    func testCallbackFiredOnRename() {
        let path = makeTempFile()
        let renamedPath = path + ".moved"
        let watcher = BundleWatcher()
        let expectation = XCTestExpectation(description: "callback fires on rename")

        watcher.start(watching: path) {
            expectation.fulfill()
        }

        try? FileManager.default.moveItem(atPath: path, toPath: renamedPath)

        wait(for: [expectation], timeout: 2.0)
        watcher.stop()
        try? FileManager.default.removeItem(atPath: renamedPath)
    }

    func testNoCallbackAfterStop() {
        let path = makeTempFile()
        let watcher = BundleWatcher()
        let expectation = XCTestExpectation(description: "callback should NOT fire")
        expectation.isInverted = true

        watcher.start(watching: path) {
            expectation.fulfill()
        }
        watcher.stop()

        try? FileManager.default.removeItem(atPath: path)

        wait(for: [expectation], timeout: 1.0)
    }
}
