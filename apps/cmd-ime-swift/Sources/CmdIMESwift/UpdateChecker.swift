import Foundation
import AppKit

@MainActor
protocol UpdateChecking {
    func check(manual: Bool)
}

@MainActor
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    @Published private(set) var state: UpdateState = .idle

    private let session: URLSession
    private var latestReleaseURL: URL?

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    func check(manual: Bool) {
        state = .checking

        guard let url = URL(string: "https://api.github.com/repos/kazuki/cmd-ime/releases/latest") else {
            state = .failed("API URLが不正です。")
            return
        }

        var request = URLRequest(url: url)
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    self.state = .failed("通信エラー: \(error.localizedDescription)")
                    return
                }

                guard
                    let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200,
                    let data = data
                else {
                    self.state = .failed("最新リリースの取得に失敗しました。")
                    return
                }

                do {
                    let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                    self.latestReleaseURL = URL(string: release.htmlUrl)

                    if self.isNewerVersion(release.tagName, than: self.currentVersion) {
                        self.state = .available(version: release.tagName)
                    } else {
                        self.state = .upToDate(self.currentVersion)
                    }
                } catch {
                    self.state = .failed("解析に失敗しました。")
                }
            }
        }

        task.resume()
    }

    func openLatestReleasePage() {
        guard let url = latestReleaseURL else { return }
        NSWorkspace.shared.open(url)
    }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    private func isNewerVersion(_ candidate: String, than current: String) -> Bool {
        func components(_ string: String) -> [Int] {
            string
                .trimmingCharacters(in: CharacterSet(charactersIn: "v"))
                .split(separator: ".")
                .map { Int($0) ?? 0 }
        }

        let lhs = components(candidate)
        let rhs = components(current)
        let count = max(lhs.count, rhs.count)

        for index in 0..<count {
            let l = index < lhs.count ? lhs[index] : 0
            let r = index < rhs.count ? rhs[index] : 0
            if l != r {
                return l > r
            }
        }

        return false
    }
}

@MainActor
extension UpdateChecker: UpdateChecking {}

enum UpdateState: Equatable {
    case idle
    case checking
    case upToDate(String)
    case available(version: String)
    case failed(String)

    var message: String {
        switch self {
        case .idle:
            return "未確認"
        case .checking:
            return "確認中…"
        case .upToDate(let version):
            return "最新バージョンです (\(version))"
        case .available(let version):
            return "新しいバージョンが見つかりました (\(version))"
        case .failed(let error):
            return "エラー: \(error)"
        }
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlUrl: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
    }
}

extension UpdateState {
    var hasUpdate: Bool {
        if case .available = self {
            return true
        }
        return false
    }
}
