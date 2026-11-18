import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Transferable wrapper so PhotosPicker hands us a real movie file.
struct PickedMovie: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + "." + (received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension))
            try FileManager.default.copyItem(at: received.file, to: dest)
            return PickedMovie(url: dest)
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var store: PlaylistStore
    @EnvironmentObject var player: PlayerManager
    @EnvironmentObject var router: Router

    enum Segment: Hashable { case videos, favorites }
    @State private var segment: Segment = .videos
    @State private var showImportChoice = false
    @State private var showPhotos = false
    @State private var showFiles = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var importing = false
    @State private var errorText: String?
    @State private var renaming: LocalVideo?
    @State private var newTitle = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    Text(L10n.t("library.videos")).tag(Segment.videos)
                    Text(L10n.t("library.favorites")).tag(Segment.favorites)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .padding(.horizontal).padding(.bottom, 8)

                if segment == .videos { videos } else { favorites }
            }
            .navigationTitle(L10n.t("tab.library"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showImportChoice = true } label: {
                        Image(systemName: "plus").font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44).background(Color(.systemGray5), in: Circle())
                    }
                    .accessibilityLabel(L10n.t("library.import"))
                }
            }
            .confirmationDialog(L10n.t("library.import"), isPresented: $showImportChoice) {
                Button(L10n.t("library.fromPhotos")) { showPhotos = true }
                Button(L10n.t("library.fromFiles")) { showFiles = true }
            }
            .photosPicker(isPresented: $showPhotos, selection: $photoItems, matching: .videos)
            .fileImporter(isPresented: $showFiles, allowedContentTypes: [.movie, .video, .mpeg4Movie, .quickTimeMovie],
                          allowsMultipleSelection: true) { result in
                if case .success(let urls) = result {
                    Task { await importFiles(urls) }
                }
            }
            .onChange(of: photoItems) { _, items in
                guard !items.isEmpty else { return }
                Task { await importPhotos(items) }
            }
            .overlay {
                if importing {
                    ProgressView(L10n.t("library.importing"))
                        .padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .alert(L10n.t("common.error"), isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
                Button(L10n.t("common.ok")) { errorText = nil }
            } message: { Text(errorText ?? "") }
            .alert(L10n.t("common.rename"), isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
                TextField("", text: $newTitle)
                Button(L10n.t("common.save")) { if let v = renaming { library.rename(v, to: newTitle) }; renaming = nil }
                Button(L10n.t("common.cancel"), role: .cancel) { renaming = nil }
            }
        }
    }

    @ViewBuilder
    private var videos: some View {
        if library.videos.isEmpty {
            EmptyStateView(icon: "tray.and.arrow.down",
                           title: L10n.t("library.emptyTitle"),
                           message: L10n.t("library.emptyBody"),
                           actionTitle: L10n.t("library.importNow"),
                           action: { showImportChoice = true })
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                    ForEach(library.videos) { v in
                        VideoTile(video: v)
                            .onTapGesture {
                                let all = library.videos.map { library.asChannel($0) }
                                player.play(library.asChannel(v), queue: all)
                                router.showPlayer = true
                            }
                            .contextMenu {
                                Button { newTitle = v.title; renaming = v } label: {
                                    Label(L10n.t("common.rename"), systemImage: "pencil")
                                }
                                Button(role: .destructive) { library.delete(v) } label: {
                                    Label(L10n.t("common.delete"), systemImage: "trash")
                                }
                            }
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private var favorites: some View {
        let favs = store.favoriteChannels
        if favs.isEmpty {
            EmptyStateView(icon: "heart", title: L10n.t("library.noFavorites"), message: L10n.t("library.noFavoritesBody"))
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                    ForEach(favs) { ch in
                        ChannelCard(channel: ch, width: nil) {
                            player.play(ch, queue: favs)
                            router.showPlayer = true
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func importPhotos(_ items: [PhotosPickerItem]) async {
        importing = true
        defer { importing = false; photoItems = [] }
        for item in items {
            do {
                if let movie = try await item.loadTransferable(type: PickedMovie.self) {
                    try await library.importVideo(from: movie.url)
                    try? FileManager.default.removeItem(at: movie.url)
                }
            } catch {
                errorText = error.localizedDescription
            }
        }
    }

    private func importFiles(_ urls: [URL]) async {
        importing = true
        defer { importing = false }
        for u in urls {
            do { try await library.importVideo(from: u) } catch { errorText = error.localizedDescription }
        }
    }
}

struct VideoTile: View {
    @EnvironmentObject var library: LibraryStore
    let video: LocalVideo
    @State private var thumb: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.12))
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .overlay {
                        if let thumb {
                            Image(uiImage: thumb).resizable().scaledToFill()
                        } else {
                            Image(systemName: "film").font(.title).foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                if video.duration > 0 {
                    Text(Duration.seconds(video.duration).formatted(.time(pattern: video.duration >= 3600 ? Duration.TimeFormatStyle.Pattern.hourMinuteSecond : Duration.TimeFormatStyle.Pattern.minuteSecond)))
                        .font(.caption2.monospacedDigit().bold()).foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(.black.opacity(0.7), in: Capsule())
                        .padding(8)
                }
            }
            Text(video.title).lineLimit(1)
        }
        .task { thumb = await library.thumbnail(for: video) }
    }
}
