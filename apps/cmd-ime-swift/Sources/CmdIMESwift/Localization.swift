//
//  Localization.swift
//  ⌘IME
//
import Foundation

// SwiftPM's generated accessor searches beside the executable bundle and
// in the build tree. The packaged app embeds its bundle in Contents/Resources.
private let localizationBundle: Bundle = {
    let main = Bundle.main
    guard main.bundleURL.pathExtension == "app" else { return .module }
    guard let url = main.url(forResource: "CmdIMESwift_CmdIMESwift", withExtension: "bundle"),
          let resources = Bundle(url: url) else { return main }
    return resources
}()

/// Looks up `key` in `Localizable.xcstrings` for the current locale. `key` is
/// a stable catalog identifier (e.g. "general.launchAtLogin"), not the
/// English display text, so English wording can change without touching
/// every other locale's key.
func L(_ key: String) -> String {
    String(localized: String.LocalizationValue(key), bundle: localizationBundle)
}
