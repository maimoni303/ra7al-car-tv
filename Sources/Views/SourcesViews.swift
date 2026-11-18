import SwiftUI
import UniformTypeIdentifiers

// MARK: - Manage Sources

struct ManageSourcesView: View {
    @EnvironmentObject var store: PlaylistStore
    @EnvironmentObject var router: Router

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if store.playlists.isEmpty {
                    EmptyStateView(icon: "antenna.radiowaves.left.and.right",
                                   title: L10n.t("home.emptyTitle"), message: L10n.t("home.emptyBody"),
                                   actionTitle: L10n.t("home.addSource"),
                                   action: { router.showAddSource = true })
                        .padding(.top, 60)
                }
                ForEach(store.playlists) { p in
                    NavigationLink { SourceDetailView(playlistID: p.id) } label: {
                        HStack(spacing: 18) {
                            Image(systemName: p.lastError == nil ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                                .font(.system(size: 26)).foregroundStyle(p.lastError == nil ? Brand.accent : Color.red)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(p.name).font(.system(size: 22, weight: .medium)).foregroundStyle(.primary)
                                Text("\(store.count(in: p).grouped) \(L10n.t("home.channels")) · \(L10n.t("sources.refreshed")) \(p.lastUpdated.relativeText())")
                                    .font(.system(size: 16)).foregroundStyle(.secondary).lineLimit(1)
                                if p.lastError != nil {
                                    Text(L10n.t("sources.broken")).font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.red).lineLimit(1)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.forward").foregroundStyle(Color(.tertiaryLabel))
                        }
                        .padding(.horizontal, 22).padding(.vertical, 20)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L10n.t("sources.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.showAddSource = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel(L10n.t("home.addSource"))
            }
        }
        .refreshable { await store.refreshDueSources(force: true) }
    }
}

struct SourceDetailView: View {
    @EnvironmentObject var store: PlaylistStore
    @Environment(\.dismiss) private var dismiss
    let playlistID: UUID
    @State private var name = ""
    @State private var refreshing = false
    @State private var errorText: String?
    @State private var confirmDelete = false

    private var playlist: Playlist? { store.playlists.first { $0.id == playlistID } }

    var body: some View {
        Form {
            if let p = playlist {
                Section(L10n.t("sources.name")) {
                    TextField(L10n.t("sources.name"), text: $name)
                        .onSubmit { store.rename(p, to: name) }
                }
                Section {
                    LabeledContent(L10n.t("home.channels"), value: store.count(in: p).grouped)
                    LabeledContent(L10n.t("sources.refreshed"), value: p.lastUpdated.relativeText())
                    LabeledContent(L10n.t("sources.status")) {
                        Text(p.lastError == nil ? L10n.t("sources.ok") : (p.lastError ?? ""))
                            .foregroundStyle(p.lastError == nil ? Brand.accent : Color.red)
                    }
                    if let u = p.sourceURL {
                        LabeledContent(L10n.t("sources.link")) {
                            Text(u.absoluteString).lineLimit(1).truncationMode(.middle).textSelection(.enabled)
                        }
                    } else {
                        LabeledContent(L10n.t("sources.link"), value: L10n.t("sources.pasted"))
                    }
                }
                if p.sourceURL != nil {
                    Section {
                        Button {
                            Task {
                                refreshing = true
                                do { try await store.refresh(p) } catch { errorText = error.localizedDescription }
                                refreshing = false
                            }
                        } label: {
                            HStack {
                                Label(L10n.t("sources.refresh"), systemImage: "arrow.clockwise")
                                if refreshing { Spacer(); ProgressView() }
                            }
                        }
                        .disabled(refreshing)
                        if let u = p.sourceURL {
                            Button { UIPasteboard.general.string = u.absoluteString } label: {
                                Label(L10n.t("common.copyLink"), systemImage: "doc.on.doc")
                            }
                        }
                    }
                }
                Section {
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label(L10n.t("common.delete"), systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(playlist?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { name = playlist?.name ?? "" }
        .onDisappear { if let p = playlist { store.rename(p, to: name) } }
        .confirmationDialog(L10n.t("sources.deleteConfirm"), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(L10n.t("common.delete"), role: .destructive) {
                if let p = playlist { store.delete(p) }
                dismiss()
            }
        }
        .alert(L10n.t("common.error"), isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
            Button(L10n.t("common.ok")) { errorText = nil }
        } message: { Text(errorText ?? "") }
    }
}

// MARK: - Add a Source

struct AddSourceView: View {
    @EnvironmentObject var store: PlaylistStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var input = ""
    @State private var loading = false
    @State private var errorText: String?
    @State private var showFile = false
    @FocusState private var focused: Bool

    private var canAdd: Bool { !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !loading }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ZStack(alignment: .bottomTrailing) {
                        TextEditor(text: $input)
                            .focused($focused)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .frame(minHeight: 150)
                            .scrollContentBackground(.hidden)
                        Button {
                            if let s = UIPasteboard.general.string { input = s }
                        } label: {
                            Label(L10n.t("add.paste"), systemImage: "doc.on.clipboard")
                                .font(.headline).foregroundStyle(.white)
                                .padding(.horizontal, 18).padding(.vertical, 11)
                                .background(Brand.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text(L10n.t("add.hint")).textCase(nil).font(.subheadline)
                }

                Section(L10n.t("add.findLink")) {
                    NavigationLink {
                        FindLinksView(onPick: { link in input = link })
                    } label: {
                        SettingsRow(icon: "safari", title: L10n.t("add.findLinks"),
                                    subtitle: L10n.t("add.findLinksBody"), showsChevron: false)
                    }
                    Button { showFile = true } label: {
                        SettingsRow(icon: "folder", title: L10n.t("add.importFile"),
                                    subtitle: L10n.t("add.importFileBody"))
                    }
                }

                Section(L10n.t("add.help")) {
                    NavigationLink { InfoPage(titleKey: "add.whatIs", bodyKey: "add.whatIsText") } label: {
                        SettingsRow(icon: "questionmark.circle", title: L10n.t("add.whatIs"),
                                    subtitle: L10n.t("add.whatIsBody"), showsChevron: false)
                    }
                    Button {
                        if let u = URL(string: "mailto:\(Brand.supportEmail)") { openURL(u) }
                    } label: {
                        SettingsRow(icon: "envelope", title: L10n.t("add.emailSupport"), subtitle: Brand.supportEmail)
                    }
                    Button {
                        if let u = URL(string: "https://wa.me/\(Brand.whatsapp)") { openURL(u) }
                    } label: {
                        SettingsRow(icon: "bubble.left.and.bubble.right", title: L10n.t("settings.whatsapp"),
                                    subtitle: L10n.t("settings.whatsappBody"))
                    }
                }
            }
            .navigationTitle(L10n.t("add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.backward") }
                        .accessibilityLabel(L10n.t("common.cancel"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if loading { ProgressView() } else {
                        Button(L10n.t("common.add")) { add() }.disabled(!canAdd).fontWeight(.semibold)
                    }
                }
            }
            .fileImporter(isPresented: $showFile,
                          allowedContentTypes: [UTType(filenameExtension: "m3u") ?? .plainText,
                                                UTType(filenameExtension: "m3u8") ?? .plainText, .plainText, .data]) { result in
                if case .success(let url) = result {
                    do { try store.importFile(url); dismiss() } catch { errorText = error.localizedDescription }
                }
            }
            .alert(L10n.t("common.error"), isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
                Button(L10n.t("common.ok")) { errorText = nil }
            } message: { Text(errorText ?? "") }
            .interactiveDismissDisabled(loading)
            .onAppear { focused = true }
        }
    }

    private func add() {
        loading = true
        Task {
            do {
                try await store.addSource(input: input)
                loading = false
                dismiss()
            } catch {
                loading = false
                errorText = error.localizedDescription
            }
        }
    }
}
