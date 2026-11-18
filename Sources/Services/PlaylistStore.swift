import Foundation

@MainActor
final class PlaylistStore: ObservableObject {
    static let shared = PlaylistStore()

    @Published private(set) var playlists: [Playlist] = []
    @Published private(set) var channelsByPlaylist: [UUID: [Channel]] = [:]
    @Published private(set) var favorites: [String] = []      // channel keys, ordered
    @Published private(set) var recents: [String] = []        // channel keys, newest first
    @Published var selectedPlaylistID: UUID?                  // nil = all playlists

    private let fm = FileManager.default
    private let maxRecents = 30

    private var dir: URL {
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RA7ALCarTV", isDirectory: true)
        if !fm.fileExists(atPath: base.path) {
            try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base
    }

    init() { load() }

    // MARK: - Derived data

    var allChannels: [Channel] {
        if let id = selectedPlaylistID { return channelsByPlaylist[id] ?? [] }
        return playlists.flatMap { channelsByPlaylist[$0.id] ?? [] }
    }

    var categories: [String] {
        var seen = Set<String>()
        var out: [String] = []
        for c in allChannels {
            let g = c.group.isEmpty ? L10n.t("cat.uncategorized") : c.group
            if seen.insert(g).inserted { out.append(g) }
        }
        return out
    }

    private var groupedCache: (key: String, value: [ChannelGroup])?

    /// Channels grouped by category in playlist order (cached; large playlists have thousands of rows).
    var grouped: [ChannelGroup] {
        let key = (selectedPlaylistID?.uuidString ?? "all") + "|" +
            playlists.map { "\($0.id.uuidString):\($0.lastUpdated.timeIntervalSince1970)" }.joined(separator: ",")
        if let cache = groupedCache, cache.key == key { return cache.value }
        let other = L10n.t("cat.uncategorized")
        var order: [String] = []
        var buckets: [String: [Channel]] = [:]
        for c in allChannels {
            // iptv-org style "Movies;Entertainment" puts a channel in several categories.
            var parts = c.group.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            if parts.isEmpty { parts = [other] }
            for g in parts {
                if buckets[g] == nil { order.append(g) }
                buckets[g, default: []].append(c)
            }
        }
        let value = order.map { ChannelGroup(name: $0, channels: buckets[$0] ?? []) }
        groupedCache = (key, value)
        return value
    }

    func channels(in category: String?) -> [Channel] {
        guard let category else { return allChannels }
        let uncategorized = L10n.t("cat.uncategorized")
        return allChannels.filter { ($0.group.isEmpty ? uncategorized : $0.group) == category }
    }

    func search(_ query: String, in list: [Channel]) -> [Channel] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return list }
        return list.filter {
            $0.name.localizedCaseInsensitiveContains(q) || $0.group.localizedCaseInsensitiveContains(q)
        }
    }

    private var everyChannel: [Channel] { playlists.flatMap { channelsByPlaylist[$0.id] ?? [] } }

    var favoriteChannels: [Channel] {
        let index = Dictionary(everyChannel.map { ($0.key, $0) }, uniquingKeysWith: { a, _ in a })
        return favorites.compactMap { index[$0] }
    }

    var recentChannels: [Channel] {
        let index = Dictionary(everyChannel.map { ($0.key, $0) }, uniquingKeysWith: { a, _ in a })
        return recents.compactMap { index[$0] }
    }

    func isFavorite(_ c: Channel) -> Bool { favorites.contains(c.key) }

    // MARK: - Mutations

    func toggleFavorite(_ c: Channel) {
        if let i = favorites.firstIndex(of: c.key) { favorites.remove(at: i) } else { favorites.append(c.key) }
        save(favorites, to: "favorites.json")
    }

    func markWatched(_ c: Channel) {
        recents.removeAll { $0 == c.key }
        recents.insert(c.key, at: 0)
        if recents.count > maxRecents { recents = Array(recents.prefix(maxRecents)) }
        save(recents, to: "recents.json")
    }

    func clearRecents() {
        recents = []
        save(recents, to: "recents.json")
    }

    @discardableResult
    func addPlaylist(name: String, urlString: String) async throws -> Playlist {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else { throw PlaylistError.invalidURL }
        let text = try await download(url)
        let id = UUID()
        let channels = try parseOrThrow(text, id: id)
        let finalName = name.trimmingCharacters(in: .whitespaces).isEmpty
            ? (url.host ?? L10n.t("playlist.default")) : name
        let p = Playlist(id: id, name: finalName, sourceURL: url, isLocalFile: false,
                         channelCount: channels.count, lastUpdated: Date())
        commit(p, channels: channels)
        return p
    }

    /// Accepts what the user pasted in "Add a Source": a link, or raw M3U text.
    @discardableResult
    func addSource(input: String, name: String = "") async throws -> Playlist {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PlaylistError.invalidURL }
        if M3UParser.looksLikeM3U(trimmed) {
            let id = UUID()
            let channels = try parseOrThrow(trimmed, id: id)
            let p = Playlist(id: id,
                             name: name.isEmpty ? L10n.t("playlist.default") + " \(playlists.count + 1)" : name,
                             sourceURL: nil, isLocalFile: true,
                             channelCount: channels.count, lastUpdated: Date())
            commit(p, channels: channels)
            return p
        }
        // Single line → treat as a link. Default name from the file name (e.g. "us" for us.m3u).
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? trimmed
        var derived = name
        if derived.isEmpty, let u = URL(string: firstLine) {
            derived = u.deletingPathExtension().lastPathComponent
            if derived.isEmpty || derived == "/" { derived = u.host ?? "" }
        }
        return try await addPlaylist(name: derived, urlString: firstLine)
    }

    func count(in playlist: Playlist) -> Int { channelsByPlaylist[playlist.id]?.count ?? 0 }

    var totalChannelCount: Int { playlists.reduce(0) { $0 + count(in: $1) } }

    @discardableResult
    func importFile(_ fileURL: URL, name: String? = nil) throws -> Playlist {
        let scoped = fileURL.startAccessingSecurityScopedResource()
        defer { if scoped { fileURL.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: fileURL)
        let text = String(decoding: data, as: UTF8.self)
        let id = UUID()
        let channels = try parseOrThrow(text, id: id)
        let p = Playlist(id: id, name: name ?? fileURL.deletingPathExtension().lastPathComponent,
                         sourceURL: nil, isLocalFile: true,
                         channelCount: channels.count, lastUpdated: Date())
        commit(p, channels: channels)
        return p
    }

    func refresh(_ playlist: Playlist) async throws {
        guard let url = playlist.sourceURL, !playlist.isLocalFile else { return }
        let text = try await download(url)
        let channels = try parseOrThrow(text, id: playlist.id)
        var p = playlist
        p.channelCount = channels.count
        p.lastUpdated = Date()
        commit(p, channels: channels)
    }

    func rename(_ playlist: Playlist, to name: String) {
        guard let i = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        let clean = name.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return }
        playlists[i].name = clean
        save(playlists, to: "playlists.json")
    }

    func delete(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        channelsByPlaylist[playlist.id] = nil
        if selectedPlaylistID == playlist.id { selectedPlaylistID = nil }
        try? fm.removeItem(at: dir.appendingPathComponent("channels-\(playlist.id.uuidString).json"))
        save(playlists, to: "playlists.json")
    }

    // MARK: - Internals

    private func parseOrThrow(_ text: String, id: UUID) throws -> [Channel] {
        let channels = M3UParser.parse(text, playlistID: id)
        if channels.isEmpty {
            throw M3UParser.looksLikeM3U(text) ? PlaylistError.emptyPlaylist : PlaylistError.notM3U
        }
        return channels
    }

    private func download(_ url: URL) async throws -> String {
        var req = URLRequest(url: url, timeoutInterval: 60)
        req.setValue("RA7AL-CarTV/1.0", forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw PlaylistError.http(http.statusCode)
        }
        return String(decoding: data, as: UTF8.self)
    }

    private func commit(_ p: Playlist, channels: [Channel]) {
        if let i = playlists.firstIndex(where: { $0.id == p.id }) { playlists[i] = p } else { playlists.append(p) }
        channelsByPlaylist[p.id] = channels
        save(playlists, to: "playlists.json")
        save(channels, to: "channels-\(p.id.uuidString).json")
    }

    private func load() {
        playlists = read([Playlist].self, from: "playlists.json") ?? []
        favorites = read([String].self, from: "favorites.json") ?? []
        recents = read([String].self, from: "recents.json") ?? []
        for p in playlists {
            channelsByPlaylist[p.id] = read([Channel].self, from: "channels-\(p.id.uuidString).json") ?? []
        }
    }

    private func save<T: Encodable>(_ value: T, to file: String) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: dir.appendingPathComponent(file), options: .atomic)
        } catch {
            print("Save failed for \(file): \(error)")
        }
    }

    private func read<T: Decodable>(_ type: T.Type, from file: String) -> T? {
        guard let data = try? Data(contentsOf: dir.appendingPathComponent(file)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
