import SwiftUI
import AVKit

// MARK: - Mini player (floating card above the tab bar)

struct MiniPlayerBar: View {
    @EnvironmentObject var player: PlayerManager
    @EnvironmentObject var store: PlaylistStore
    var onOpen: () -> Void

    var body: some View {
        if let c = player.current {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color.black)
                    if player.errorMessage != nil {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                    } else if let logo = c.logo {
                        AsyncImage(url: logo) { $0.resizable().scaledToFit().padding(5) } placeholder: { Color.clear }
                    } else {
                        Image(systemName: "play.tv").foregroundStyle(.white)
                    }
                }
                .frame(width: 62, height: 46)

                Text(c.name).font(.system(size: 17, weight: .medium)).lineLimit(1)
                Spacer(minLength: 4)

                Button { store.toggleFavorite(c) } label: {
                    Image(systemName: store.isFavorite(c) ? "heart.fill" : "heart")
                        .font(.system(size: 21))
                        .foregroundStyle(store.isFavorite(c) ? Color.red : Color.primary)
                }
                .accessibilityLabel(L10n.t("common.favorite"))

                Button {
                    if player.errorMessage != nil { player.retry() } else { player.togglePlay() }
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 22))
                }
                .accessibilityLabel(L10n.t(player.isPlaying ? "player.pause" : "player.play"))

                Button { withAnimation { player.stop() } } label: {
                    Image(systemName: "xmark").font(.system(size: 20, weight: .semibold))
                }
                .accessibilityLabel(L10n.t("player.close"))
            }
            .foregroundStyle(.primary)
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
            .accessibilityIdentifier("miniPlayer")
            .shadow(color: .black.opacity(0.1), radius: 14, y: 4)
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
        }
    }
}

// MARK: - Channel card (16:9 dark tile with centered logo)

struct ChannelCard: View {
    @EnvironmentObject var store: PlaylistStore
    @EnvironmentObject var player: PlayerManager
    let channel: Channel
    var width: CGFloat? = 230
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.12))
                if let logo = channel.logo {
                    AsyncImage(url: logo) { phase in
                        if let img = phase.image {
                            img.resizable().scaledToFit().frame(maxWidth: 110, maxHeight: 70)
                        } else {
                            initials
                        }
                    }
                } else {
                    initials
                }
                if player.current?.id == channel.id {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "waveform").font(.caption.bold())
                                .padding(6).background(Brand.accent, in: Circle()).foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.black.opacity(0.6), lineWidth: 2))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

            Text(channel.name).font(.system(size: 17)).lineLimit(1)
        }
        .frame(width: width)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("channel-\(channel.name)")
        .contextMenu {
            Button { store.toggleFavorite(channel) } label: {
                Label(L10n.t(store.isFavorite(channel) ? "common.unfavorite" : "common.favorite"),
                      systemImage: store.isFavorite(channel) ? "heart.slash" : "heart")
            }
            Button { UIPasteboard.general.string = channel.url.absoluteString } label: {
                Label(L10n.t("common.copyLink"), systemImage: "doc.on.doc")
            }
        }
    }

    private var initials: some View {
        Text(String(channel.name.prefix(2)).uppercased())
            .font(.system(size: 28, weight: .bold)).foregroundStyle(.white.opacity(0.85))
    }
}

// MARK: - Shared building blocks

struct SearchField: View {
    let prompt: String
    @Binding var text: String
    var onSubmit: () -> Void = {}

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit(onSubmit)
            if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .accessibilityLabel(L10n.t("common.clear"))
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(Color(.systemGray6), in: Capsule())
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 64, weight: .light)).foregroundStyle(Color(.systemGray3))
            Text(title).font(.title3.weight(.semibold))
            Text(message).multilineTextAlignment(.center).foregroundStyle(.secondary)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).font(.headline).foregroundStyle(.white)
                        .padding(.horizontal, 44).padding(.vertical, 16)
                        .background(Brand.accent, in: Capsule())
                }
                .padding(.top, 8)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CircleIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName).font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 46, height: 46)
                .background(Color(.systemGray5), in: Circle())
        }
        .accessibilityLabel(label)
    }
}

/// Settings-style row: green icon, title, optional subtitle, value and chevron.
struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String?
    var value: String?
    var showsChevron = true

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(Brand.accent).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 19)).foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle).font(.system(size: 15)).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if let value { Text(value).foregroundStyle(.secondary) }
            if showsChevron {
                Image(systemName: "chevron.forward").font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView()
        v.prioritizesVideoDevices = true
        v.activeTintColor = UIColor(Brand.accent)
        v.tintColor = .white
        return v
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

extension Date {
    func relativeText() -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: L10n.current)
        f.unitsStyle = .full
        return f.localizedString(for: self, relativeTo: Date())
    }
}

extension Int {
    var grouped: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: L10n.current == "ar" ? "ar_SA@numbers=latn" : "en_US")
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
