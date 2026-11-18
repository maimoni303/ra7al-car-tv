import SwiftUI
import WebKit

struct PopularSite: Identifiable {
    var id: String { url }
    let name: String
    let url: String
}

enum PopularSites {
    static let all: [PopularSite] = [
        .init(name: "Google", url: "https://www.google.com"),
        .init(name: "YouTube", url: "https://m.youtube.com"),
        .init(name: "Netflix", url: "https://www.netflix.com"),
        .init(name: "Prime Video", url: "https://www.primevideo.com"),
        .init(name: "Shahid", url: "https://shahid.mbc.net"),
        .init(name: "Disney+", url: "https://www.disneyplus.com"),
        .init(name: "HBO Max", url: "https://www.max.com"),
        .init(name: "TikTok", url: "https://www.tiktok.com"),
        .init(name: "Instagram", url: "https://www.instagram.com"),
        .init(name: "OSN+", url: "https://osnplus.com"),
        .init(name: "Paramount+", url: "https://www.paramountplus.com"),
        .init(name: "YouTube TV", url: "https://tv.youtube.com"),
        .init(name: "Apple TV", url: "https://tv.apple.com"),
        .init(name: "Twitch", url: "https://www.twitch.tv"),
        .init(name: "STARZPLAY", url: "https://starzplay.com"),
        .init(name: "Tubi", url: "https://tubitv.com"),
        .init(name: "Spotify", url: "https://open.spotify.com"),
        .init(name: "Anghami", url: "https://www.anghami.com"),
        .init(name: "Crunchyroll", url: "https://www.crunchyroll.com"),
        .init(name: "Pluto TV", url: "https://pluto.tv")
    ]
}

/// Site icon loaded at runtime from the site's favicon, with a letter fallback.
struct SiteIcon: View {
    let url: URL
    let name: String
    var size: CGFloat = 76

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemGroupedBackground))
            AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?sz=128&domain=\(url.host ?? "")")) { phase in
                if let img = phase.image {
                    img.resizable().scaledToFit().padding(size * 0.18)
                } else {
                    Text(String(name.prefix(1))).font(.system(size: size * 0.42, weight: .bold))
                        .foregroundStyle(Brand.accent)
                }
            }
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
    }
}

struct BrowserView: View {
    @EnvironmentObject var browser: BrowserStore
    @State private var text = ""
    @State private var openPage: PageRoute?
    @State private var showTabs = false

    struct PageRoute: Identifiable { let id = UUID(); let url: URL; var tabIndex: Int? }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    SearchField(prompt: L10n.t("browser.search"), text: $text) { go(text) }

                    if let last = browser.lastPage {
                        Button { open(last.url) } label: {
                            HStack(spacing: 14) {
                                SiteIcon(url: last.url, name: last.title, size: 54)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(L10n.t("browser.continue")).font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Brand.accent)
                                    Text(last.title).font(.headline).lineLimit(1).foregroundStyle(.primary)
                                    Text(last.url.host ?? "").font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.forward").foregroundStyle(.secondary)
                            }
                            .padding(16)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)
                    }

                    if !browser.recents.isEmpty {
                        Text(L10n.t("browser.recent")).font(.title2.bold())
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 18) {
                                ForEach(browser.recents) { s in
                                    siteTile(name: s.title, url: s.url)
                                }
                            }
                        }
                    }

                    Text(L10n.t("browser.popular")).font(.title2.bold())
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 20) {
                        ForEach(PopularSites.all) { s in
                            if let u = URL(string: s.url) { siteTile(name: s.name, url: u) }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(L10n.t("tab.browser"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 18) {
                        Menu {
                            Button(role: .destructive) { browser.clearHistory() } label: {
                                Label(L10n.t("browser.clearHistory"), systemImage: "trash")
                            }
                            Toggle(isOn: Binding(get: { AppSettings.shared.blockAds },
                                                 set: { AppSettings.shared.blockAds = $0 })) {
                                Label(L10n.t("settings.blockAds"), systemImage: "hand.raised")
                            }
                        } label: { Image(systemName: "line.3.horizontal") }
                        Button { showTabs = true } label: {
                            Text("\(max(browser.tabs.count, 1))")
                                .font(.system(size: 13, weight: .bold))
                                .frame(width: 24, height: 24)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(lineWidth: 2))
                        }
                        .accessibilityLabel(L10n.t("browser.tabs"))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Color(.systemGray5), in: Capsule())
                }
            }
            .fullScreenCover(item: $openPage) { route in
                WebPageView(startURL: route.url, tabIndex: route.tabIndex)
            }
            .sheet(isPresented: $showTabs) {
                TabsSheet { index in
                    showTabs = false
                    if let s = browser.tabs[safe: index] {
                        openPage = PageRoute(url: s.url, tabIndex: index)
                    }
                } onNew: {
                    showTabs = false
                    openPage = PageRoute(url: URL(string: "https://www.google.com")!, tabIndex: nil)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func siteTile(name: String, url: URL) -> some View {
        Button { open(url) } label: {
            VStack(spacing: 8) {
                SiteIcon(url: url, name: name)
                Text(name).font(.system(size: 15)).lineLimit(1).foregroundStyle(.primary)
            }
            .frame(maxWidth: 90)
        }
        .buttonStyle(.plain)
    }

    private func go(_ input: String) {
        guard let u = BrowserStore.resolve(input) else { return }
        text = ""
        open(u)
    }

    private func open(_ url: URL) {
        openPage = PageRoute(url: url, tabIndex: nil)
    }
}

struct TabsSheet: View {
    @EnvironmentObject var browser: BrowserStore
    let onSelect: (Int) -> Void
    let onNew: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(browser.tabs.enumerated()), id: \.offset) { i, s in
                    Button { onSelect(i) } label: {
                        HStack {
                            SiteIcon(url: s.url, name: s.title, size: 36)
                            VStack(alignment: .leading) {
                                Text(s.title).lineLimit(1).foregroundStyle(.primary)
                                Text(s.url.host ?? "").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { idx in idx.sorted(by: >).forEach { browser.closeTab($0) } }
            }
            .overlay {
                if browser.tabs.isEmpty {
                    Text(L10n.t("browser.noTabs")).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(L10n.t("browser.tabs"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onNew) { Image(systemName: "plus") }
                        .accessibilityLabel(L10n.t("browser.newTab"))
                }
            }
        }
    }
}

// MARK: - Web page

@MainActor
final class WebModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    let webView: WKWebView
    @Published var title = ""
    @Published var url: URL?
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var progress = 0.0
    private var observers: [NSKeyValueObservation] = []

    override init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        observers = [
            webView.observe(\.estimatedProgress) { [weak self] w, _ in
                let p = w.estimatedProgress
                Task { @MainActor in self?.progress = p }
            },
            webView.observe(\.title) { [weak self] w, _ in
                let t = w.title ?? ""
                Task { @MainActor in self?.title = t }
            },
            webView.observe(\.url) { [weak self] w, _ in
                let u = w.url
                Task { @MainActor in self?.url = u }
            },
            webView.observe(\.canGoBack) { [weak self] w, _ in
                let b = w.canGoBack
                Task { @MainActor in self?.canGoBack = b }
            },
            webView.observe(\.canGoForward) { [weak self] w, _ in
                let f = w.canGoForward
                Task { @MainActor in self?.canGoForward = f }
            }
        ]
        Task { await AdBlocker.apply(to: config.userContentController, enabled: AppSettings.shared.blockAds) }
    }

    func load(_ url: URL) { webView.load(URLRequest(url: url)) }

    // Open target=_blank links in the same view.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
        return nil
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct WebPageView: View {
    @EnvironmentObject var browser: BrowserStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = WebModel()
    let startURL: URL
    @State var tabIndex: Int?
    @State private var address = ""
    @FocusState private var editing: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button { dismiss() } label: { Image(systemName: "xmark").font(.headline) }
                    .accessibilityLabel(L10n.t("player.close"))
                TextField(L10n.t("browser.search"), text: $address)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .keyboardType(.webSearch).submitLabel(.go)
                    .focused($editing)
                    .onSubmit { if let u = BrowserStore.resolve(address) { model.load(u) } }
                    .padding(.horizontal, 12).frame(height: 40)
                    .background(Color(.systemGray6), in: Capsule())
                Button { model.webView.reload() } label: { Image(systemName: "arrow.clockwise") }
                    .accessibilityLabel(L10n.t("browser.reload"))
            }
            .padding(.horizontal).padding(.vertical, 8)

            if model.progress < 1 {
                ProgressView(value: model.progress).tint(Brand.accent)
            }

            WebViewRepresentable(webView: model.webView)

            HStack {
                Button { model.webView.goBack() } label: { Image(systemName: "chevron.backward") }
                    .disabled(!model.canGoBack)
                    .accessibilityLabel(L10n.t("browser.back"))
                Spacer()
                Button { model.webView.goForward() } label: { Image(systemName: "chevron.forward") }
                    .disabled(!model.canGoForward)
                    .accessibilityLabel(L10n.t("browser.forward"))
                Spacer()
                if let u = model.url {
                    ShareLink(item: u) { Image(systemName: "square.and.arrow.up") }
                }
                Spacer()
                Button { MirrorReceiver.showBroadcastPicker() } label: {
                    Image(systemName: "rectangle.on.rectangle")
                }
                .accessibilityLabel(L10n.t("cast.start"))
            }
            .font(.title3)
            .padding(.horizontal, 30).padding(.vertical, 12)
            .background(.bar)
        }
        .onAppear {
            address = startURL.absoluteString
            model.load(startURL)
            if tabIndex == nil {
                tabIndex = browser.openTab(.init(title: startURL.host ?? "", url: startURL))
            }
        }
        .onChange(of: model.url) { _, u in
            guard let u, !editing else { return }
            address = u.absoluteString
            record()
        }
        .onChange(of: model.title) { _, _ in record() }
    }

    private func record() {
        guard let u = model.url else { return }
        let site = BrowserStore.Site(title: model.title.isEmpty ? (u.host ?? "") : model.title, url: u)
        browser.visited(site)
        if let i = tabIndex { browser.updateTab(i, site) }
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
