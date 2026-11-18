import Foundation

/// Used only by UI tests (launch argument `-seedDemo`): loads a small sample source
/// so every screen can be exercised without network access.
@MainActor
enum DemoSeed {
    static var isUITest: Bool { ProcessInfo.processInfo.arguments.contains("-seedDemo") }

    static func applyIfNeeded() async {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-uiLang"), args.indices.contains(i + 1) {
            AppSettings.shared.language = args[i + 1]
        }
        if let i = args.firstIndex(of: "-uiAppearance"), args.indices.contains(i + 1) {
            AppSettings.shared.appearance = args[i + 1]
        }
        guard isUITest, PlaylistStore.shared.playlists.isEmpty else { return }
        _ = try? await PlaylistStore.shared.addSource(input: sample, name: "demo")
    }

    static let sample = """
    #EXTM3U
    #EXTINF:-1 group-title="News",Al Arabiya
    https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8
    #EXTINF:-1 group-title="News",Sky News Arabia
    https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8
    #EXTINF:-1 group-title="Movies;Entertainment",Top Gear (720p)
    https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8
    #EXTINF:-1 group-title="Movies",24 Hour Free Movies
    https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8
    #EXTINF:-1 group-title="Sports",Sports One
    https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8
    #EXTINF:-1 group-title="Kids",Kids TV
    https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8
    """
}
