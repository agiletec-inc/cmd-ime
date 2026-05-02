//
//  checkUpdate.swift
//  ⌘IME
//
//  MIT License
//

import Cocoa

private let releasesAPIURL = URL(
    string: "https://api.github.com/repos/agiletec-inc/cmd-ime/releases/latest"
)!

/// Check GitHub for a newer release. Calls back on the main queue.
///
/// - Parameters:
///   - manual: when `true`, also surface an alert if the app is up to date
///     or the request fails. Set to `false` for the silent on-launch check.
///   - callback: invoked with `true` if a newer version is available,
///     `false` if up to date, and `nil` on network/parse error.
func checkUpdate(manual: Bool = false, _ callback: ((_ isNewVer: Bool?) -> Void)? = nil) {
    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

    var request = URLRequest(url: releasesAPIURL)
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("CmdIME/\(currentVersion)", forHTTPHeaderField: "User-Agent")
    request.timeoutInterval = 10

    URLSession.shared.dataTask(with: request) { data, response, _ in
        let result = parseLatestRelease(data: data, response: response)

        DispatchQueue.main.async {
            switch result {
            case .failure:
                if manual {
                    let alert = NSAlert()
                    alert.messageText = "Could not check for updates"
                    alert.informativeText = "Please check your network connection and try again."
                    alert.runModal()
                }
                callback?(nil)

            case .success(let release):
                let hasNewer = isNewer(latest: release.version, current: currentVersion)

                if hasNewer {
                    let alert = NSAlert()
                    alert.messageText = "⌘IME \(release.version) is available"
                    alert.informativeText = release.notes.isEmpty
                        ? "A newer version is available on GitHub."
                        : release.notes
                    alert.addButton(withTitle: "Download")
                    alert.addButton(withTitle: "Later")
                    if alert.runModal() == .alertFirstButtonReturn {
                        NSWorkspace.shared.open(release.url)
                    }
                } else if manual {
                    let alert = NSAlert()
                    alert.messageText = "⌘IME is up to date"
                    alert.informativeText = "You are running version \(currentVersion)."
                    alert.runModal()
                }

                callback?(hasNewer)
            }
        }
    }.resume()
}

private struct LatestRelease {
    let version: String
    let url: URL
    let notes: String
}

private enum Result {
    case success(LatestRelease)
    case failure
}

private func parseLatestRelease(data: Data?, response: URLResponse?) -> Result {
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
          let data = data,
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let tag = json["tag_name"] as? String,
          let urlString = json["html_url"] as? String,
          let url = URL(string: urlString)
    else {
        return .failure
    }

    let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    let notes = (json["body"] as? String) ?? ""
    return .success(LatestRelease(version: version, url: url, notes: notes))
}

/// Semver-aware comparison. Returns true when `latest` is strictly greater than `current`.
private func isNewer(latest: String, current: String) -> Bool {
    let latestParts = latest.split(separator: ".").compactMap { Int($0) }
    let currentParts = current.split(separator: ".").compactMap { Int($0) }
    let count = max(latestParts.count, currentParts.count)
    for i in 0..<count {
        let l = i < latestParts.count ? latestParts[i] : 0
        let c = i < currentParts.count ? currentParts[i] : 0
        if l != c { return l > c }
    }
    return false
}
