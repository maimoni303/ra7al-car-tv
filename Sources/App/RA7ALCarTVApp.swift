import SwiftUI

@main
struct RA7ALCarTVApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var store = PlaylistStore.shared
    @StateObject private var player = PlayerManager.shared
    @StateObject private var car = CarState.shared
    @StateObject private var library = LibraryStore.shared
    @StateObject private var browser = BrowserStore.shared
    @StateObject private var mirror = MirrorReceiver.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(store)
                .environmentObject(player)
                .environmentObject(car)
                .environmentObject(library)
                .environmentObject(browser)
                .environmentObject(mirror)
                .environment(\.layoutDirection, settings.layoutDirection)
                .environment(\.locale, settings.locale)
                .preferredColorScheme(settings.colorScheme)
                .tint(Brand.accent)
                .id(settings.resolvedLanguage)   // rebuild texts instantly on language switch
        }
    }
}

enum AppTab: Int, CaseIterable {
    case home, browser, cast, library, settings

    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .browser: return "tab.browser"
        case .cast: return "tab.cast"
        case .library: return "tab.library"
        case .settings: return "tab.settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .browser: return "globe"
        case .cast: return "tv.fill"
        case .library: return "square.stack.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

/// Lets any screen jump to another tab or open the full player / add-source sheet.
@MainActor
final class Router: ObservableObject {
    @Published var tab: AppTab = .home
    @Published var showPlayer = false
    @Published var showAddSource = false
}

struct RootView: View {
    @EnvironmentObject var player: PlayerManager
    @StateObject private var router = Router()

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    screen(for: tab)
                        .opacity(router.tab == tab ? 1 : 0)
                        .allowsHitTesting(router.tab == tab)
                        .accessibilityHidden(router.tab != tab)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: player.current == nil ? 74 : 150)
            }

            VStack(spacing: 10) {
                if player.current != nil {
                    MiniPlayerBar(onOpen: { router.showPlayer = true })
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                FloatingTabBar(selection: $router.tab)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 4)
            .animation(.spring(duration: 0.3), value: player.current?.id)
        }
        .environmentObject(router)
        .fullScreenCover(isPresented: $router.showPlayer) {
            PlayerScreen().environmentObject(router)
        }
        .sheet(isPresented: $router.showAddSource) {
            AddSourceView().environmentObject(router)
        }
    }

    @ViewBuilder
    private func screen(for tab: AppTab) -> some View {
        switch tab {
        case .home: HomeView()
        case .browser: BrowserView()
        case .cast: CastView()
        case .library: LibraryView()
        case .settings: SettingsView()
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.25)) { selection = tab }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon).font(.system(size: 21, weight: .semibold))
                        Text(L10n.t(tab.titleKey)).font(.system(size: 11, weight: .medium))
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(selection == tab ? Brand.accent : Color.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if selection == tab {
                            Capsule().fill(Color(.systemGray5))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(5)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}
