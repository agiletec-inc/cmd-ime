import XCTest
@testable import CmdIMESwift

/// Verifies `Localizable.xcstrings` (the source of truth, shipped alongside the
/// compiled resources for reference) and its compiled `<locale>.lproj/
/// Localizable.strings` tables (what `L(_:)` actually looks up at runtime via
/// `Bundle.module`, see Localization.swift) stay complete and in sync.
///
/// `String(localized:bundle:locale:)`'s `locale:` parameter does not override
/// `Bundle.module`'s resolved localization on this toolchain — it always
/// follows `Bundle.preferredLocalizations` (confirmed empirically: passing
/// `locale: Locale(identifier: "en")` on a Japanese-locale machine still
/// returned the Japanese value). So this reads each locale's compiled table
/// directly via `Bundle.module.path(forResource:forLocalization:)` instead,
/// which does select per locale correctly, and is exactly what ships in the
/// app.
final class LocalizationCatalogTests: XCTestCase {
    static let supportedLocales = ["en", "ja", "zh-Hans", "zh-Hant", "ko", "vi"]

    /// Sanity check on the actual production entry point (`L(_:)`): it must
    /// resolve to a real translated string, not silently fall back to
    /// returning the raw key (which is what a missing/unbundled resource
    /// looks like, and what the earlier Bundle.main-vs-Bundle.module bug
    /// this file's mechanism replaces would have produced).
    func testLHelperResolvesAKnownKeyToATranslatedValue() {
        let resolved = L("general.launchAtLogin")
        XCTAssertNotEqual(resolved, "general.launchAtLogin", "L(_:) must not return the raw catalog key")
        XCTAssertFalse(resolved.isEmpty)
    }

    func testAllCatalogKeysResolveInEverySupportedLocale() throws {
        let sourceKeys = try loadSourceCatalogKeys()
        XCTAssertFalse(sourceKeys.isEmpty, "the source catalog should not be empty")

        for locale in Self.supportedLocales {
            let table = try loadCompiledTable(for: locale)
            for key in sourceKeys.sorted() {
                guard let value = table[key] else {
                    XCTFail("\(locale): missing translation for key \"\(key)\"")
                    continue
                }
                XCTAssertFalse(value.isEmpty, "\(locale): empty translation for key \"\(key)\"")
            }
        }
    }

    func testCompiledTablesHaveNoKeysBeyondTheSourceCatalog() throws {
        // Catches stale keys left in a compiled table after a key was renamed
        // or removed from the source catalog but the compiled output wasn't
        // regenerated (see README/CLAUDE.md for the regeneration command).
        let sourceKeys = try loadSourceCatalogKeys()

        for locale in Self.supportedLocales {
            let table = try loadCompiledTable(for: locale)
            let extraKeys = Set(table.keys).subtracting(sourceKeys)
            XCTAssertTrue(extraKeys.isEmpty,
                         "\(locale): compiled table has stale keys not in the source catalog: \(extraKeys)")
        }
    }

    func testCompiledTablesMatchAFreshCompileOfTheSourceCatalog() throws {
        // Detects drift: someone edited Localizable.xcstrings without
        // re-running xcstringstool compile to refresh the committed
        // Resources/<locale>.lproj output (see CLAUDE.md for the command).
        guard let xcstringsToolPath = findXcstringsTool() else {
            throw XCTSkip("xcstringstool not available in this environment")
        }
        guard let sourceURL = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings") else {
            throw XCTSkip("Localizable.xcstrings not bundled")
        }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cmdime-xcstrings-drift-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcstringsToolPath)
        process.arguments = [
            "compile", sourceURL.path,
            "--output-directory", tempDir.path,
            "--serialization-format", "text"
        ]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw XCTSkip("xcstringstool compile failed in this environment (status \(process.terminationStatus))")
        }

        for locale in Self.supportedLocales {
            let freshPath = tempDir.appendingPathComponent("\(locale).lproj/Localizable.strings").path
            guard let freshDict = NSDictionary(contentsOfFile: freshPath) as? [String: String] else {
                XCTFail("\(locale): fresh compile did not produce a readable table")
                continue
            }
            let committed = try loadCompiledTable(for: locale)
            XCTAssertEqual(committed, freshDict,
                           "\(locale): committed Resources/\(locale).lproj/Localizable.strings is stale — " +
                           "re-run xcstringstool compile on Localizable.xcstrings")
        }
    }

    // MARK: - Helpers

    private func loadSourceCatalogKeys() throws -> Set<String> {
        guard let url = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings") else {
            throw XCTSkip("Localizable.xcstrings not bundled")
        }
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = json["strings"] as? [String: Any] else {
            XCTFail("Localizable.xcstrings did not parse as expected")
            return []
        }
        return Set(strings.keys)
    }

    private func loadCompiledTable(for locale: String) throws -> [String: String] {
        guard let path = Bundle.module.path(
            forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: locale
        ) else {
            XCTFail("\(locale): no compiled Localizable.strings found")
            return [:]
        }
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            XCTFail("\(locale): Localizable.strings did not parse as a string table")
            return [:]
        }
        return dict
    }

    private func findXcstringsTool() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["--find", "xcstringstool"]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
        } catch {
            return nil
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return path.isEmpty ? nil : path
    }
}
