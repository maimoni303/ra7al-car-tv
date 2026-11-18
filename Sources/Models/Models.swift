import Foundation

struct Channel: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var url: URL
    var logo: URL?
    var group: String
    var tvgID: String?
    var playlistID: UUID

    /// Stable key used for favorites and history (survives playlist refreshes).
    var key: String { url.absoluteString }
}

struct ChannelGroup: Identifiable {
    var id: String { name }
    let name: String
    let channels: [Channel]
}

struct Playlist: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var sourceURL: URL?
    var isLocalFile: Bool
    var channelCount: Int
    var lastUpdated: Date
    /// Last daily check result: nil = link works, otherwise the error shown on the source card.
    var lastError: String?
    var lastChecked: Date?
}

enum PlaylistError: LocalizedError {
    case invalidURL
    case emptyPlaylist
    case notM3U
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return L10n.t("err.invalidURL")
        case .emptyPlaylist: return L10n.t("err.empty")
        case .notM3U: return L10n.t("err.notM3U")
        case .http(let code): return L10n.t("err.http") + " (\(code))"
        }
    }
}
