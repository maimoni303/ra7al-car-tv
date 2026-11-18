import Foundation
import AVFoundation
import UIKit

struct LocalVideo: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var fileName: String
    var added: Date
    var duration: Double
}

/// Videos the user imports from Photos or Files to play on the road.
@MainActor
final class LibraryStore: ObservableObject {
    static let shared = LibraryStore()

    @Published private(set) var videos: [LocalVideo] = []
    private let fm = FileManager.default

    var folder: URL {
        let dir = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Videos", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var indexURL: URL { folder.appendingPathComponent(".library.json") }

    init() {
        if let data = try? Data(contentsOf: indexURL),
           let list = try? JSONDecoder().decode([LocalVideo].self, from: data) {
            videos = list.filter { fm.fileExists(atPath: folder.appendingPathComponent($0.fileName).path) }
        }
    }

    func url(for v: LocalVideo) -> URL { folder.appendingPathComponent(v.fileName) }

    /// Copies a picked file into the app's library.
    func importVideo(from source: URL, title: String? = nil) async throws {
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }
        let ext = source.pathExtension.isEmpty ? "mov" : source.pathExtension
        let id = UUID()
        let dest = folder.appendingPathComponent("\(id.uuidString).\(ext)")
        try fm.copyItem(at: source, to: dest)
        let asset = AVURLAsset(url: dest)
        let seconds = (try? await asset.load(.duration).seconds) ?? 0
        let v = LocalVideo(id: id,
                           title: title ?? source.deletingPathExtension().lastPathComponent,
                           fileName: dest.lastPathComponent, added: Date(),
                           duration: seconds.isFinite ? seconds : 0)
        videos.insert(v, at: 0)
        save()
    }

    func rename(_ v: LocalVideo, to title: String) {
        guard let i = videos.firstIndex(of: v), !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        videos[i].title = title
        save()
    }

    func delete(_ v: LocalVideo) {
        try? fm.removeItem(at: url(for: v))
        videos.removeAll { $0.id == v.id }
        save()
    }

    /// A playable channel wrapper so the shared player can play local videos too.
    func asChannel(_ v: LocalVideo) -> Channel {
        Channel(id: "local|" + v.id.uuidString, name: v.title, url: url(for: v), logo: nil,
                group: L10n.t("tab.library"), tvgID: nil, playlistID: v.id)
    }

    func thumbnail(for v: LocalVideo) async -> UIImage? {
        let gen = AVAssetImageGenerator(asset: AVURLAsset(url: url(for: v)))
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 480, height: 270)
        guard let cg = try? await gen.image(at: CMTime(seconds: 1, preferredTimescale: 600)).image else { return nil }
        return UIImage(cgImage: cg)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(videos) { try? data.write(to: indexURL, options: .atomic) }
    }
}

/// Browser state: open tabs, recently visited sites and the "Continue" page.
@MainActor
final class BrowserStore: ObservableObject {
    static let shared = BrowserStore()

    struct Site: Identifiable, Codable, Hashable {
        var id: String { url.absoluteString }
        var title: String
        var url: URL
    }

    @Published var tabs: [Site] = []
    @Published private(set) var recents: [Site] = []
    @Published var lastPage: Site?

    private let defaults = UserDefaults.standard

    init() {
        if let d = defaults.data(forKey: "browser.recents"), let r = try? JSONDecoder().decode([Site].self, from: d) {
            recents = r
        }
        if let d = defaults.data(forKey: "browser.last"), let s = try? JSONDecoder().decode(Site.self, from: d) {
            lastPage = s
        }
        if let d = defaults.data(forKey: "browser.tabs"), let t = try? JSONDecoder().decode([Site].self, from: d) {
            tabs = t
        }
    }

    func visited(_ site: Site) {
        lastPage = site
        recents.removeAll { $0.url.host == site.url.host }
        recents.insert(site, at: 0)
        if recents.count > 8 { recents = Array(recents.prefix(8)) }
        persist()
    }

    func openTab(_ site: Site) -> Int {
        tabs.append(site)
        persist()
        return tabs.count - 1
    }

    func updateTab(_ index: Int, _ site: Site) {
        guard tabs.indices.contains(index) else { return }
        tabs[index] = site
        persist()
    }

    func closeTab(_ index: Int) {
        guard tabs.indices.contains(index) else { return }
        tabs.remove(at: index)
        persist()
    }

    func clearHistory() {
        recents = []
        lastPage = nil
        persist()
    }

    /// Turns typed text into a URL: a website if it looks like one, otherwise a Google search.
    nonisolated static func resolve(_ text: String) -> URL? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        if let u = URL(string: t), let s = u.scheme, ["http", "https"].contains(s.lowercased()) { return u }
        if !t.contains(" "), t.contains("."), let u = URL(string: "https://" + t) { return u }
        var c = URLComponents(string: "https://www.google.com/search")!
        c.queryItems = [URLQueryItem(name: "q", value: t)]
        return c.url
    }

    private func persist() {
        let enc = JSONEncoder()
        defaults.set(try? enc.encode(recents), forKey: "browser.recents")
        defaults.set(try? enc.encode(lastPage), forKey: "browser.last")
        defaults.set(try? enc.encode(tabs), forKey: "browser.tabs")
    }
}
