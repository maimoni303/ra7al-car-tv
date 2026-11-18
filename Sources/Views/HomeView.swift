import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: PlaylistStore
    @EnvironmentObject var player: PlayerManager
    @EnvironmentObject var router: Router
    @State private var query = ""

    private var results: [Channel] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        return Array(store.search(query, in: store.allChannels).prefix(300))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SearchField(prompt: L10n.t("home.search"), text: $query)
                        .padding(.horizontal)

                    if store.playlists.isEmpty {
                        EmptyStateView(icon: "antenna.radiowaves.left.and.right",
                                       title: L10n.t("home.emptyTitle"),
                                       message: L10n.t("home.emptyBody"),
                                       actionTitle: L10n.t("home.addSource"),
                                       action: { router.showAddSource = true })
                            .padding(.top, 60)
                    } else if !query.isEmpty {
                        searchResults
                    } else {
                        ForEach(store.grouped) { group in
                            CategoryRow(name: group.name, channels: group.channels) { ch in
                                play(ch, in: group.channels)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle(L10n.t("tab.home"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { sourceMenu }
            }
            .navigationDestination(for: CategoryRoute.self) { route in
                CategoryGridView(title: route.name)
            }
        }
    }

    private var sourceMenu: some View {
        Menu {
            Picker(selection: $store.selectedPlaylistID) {
                Text("\(L10n.t("home.allSources")) (\(store.totalChannelCount.grouped))").tag(UUID?.none)
                ForEach(store.playlists) { p in
                    Text("\(p.name) (\(store.count(in: p).grouped))").tag(UUID?.some(p.id))
                }
            } label: { EmptyView() }
            Divider()
            Button { router.showAddSource = true } label: { Label(L10n.t("common.add"), systemImage: "plus") }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray5), in: Circle())
        }
        .accessibilityLabel(L10n.t("home.sources"))
    }

    @ViewBuilder
    private var searchResults: some View {
        if results.isEmpty {
            Text(L10n.t("home.noResults")).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity).padding(.top, 40)
        } else {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                ForEach(results) { ch in
                    ChannelCard(channel: ch, width: nil) { play(ch, in: results) }
                }
            }
            .padding(.horizontal)
        }
    }

    private func play(_ ch: Channel, in list: [Channel]) {
        player.play(ch, queue: list)
        router.showPlayer = true
    }
}

struct CategoryRoute: Hashable { let name: String }

struct CategoryRow: View {
    let name: String
    let channels: [Channel]
    let onPlay: (Channel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: CategoryRoute(name: name)) {
                HStack {
                    Text(name).font(.system(size: 24, weight: .bold)).foregroundStyle(.primary)
                    Spacer()
                    Text("\(channels.count.grouped) \(L10n.t("home.channels"))")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.forward").font(.body.weight(.semibold)).foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(channels.prefix(25)) { ch in
                        ChannelCard(channel: ch) { onPlay(ch) }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CategoryGridView: View {
    @EnvironmentObject var store: PlaylistStore
    @EnvironmentObject var player: PlayerManager
    @EnvironmentObject var router: Router
    let title: String
    @State private var query = ""

    private var channels: [Channel] {
        let list = store.grouped.first { $0.name == title }?.channels ?? []
        return store.search(query, in: list)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                ForEach(channels) { ch in
                    ChannelCard(channel: ch, width: nil) {
                        player.play(ch, queue: channels)
                        router.showPlayer = true
                    }
                }
            }
            .padding()
        }
        .navigationTitle(title)
        .searchable(text: $query, prompt: L10n.t("home.search"))
    }
}
