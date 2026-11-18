import SwiftUI
import AVKit

struct PlayerScreen: View {
    @EnvironmentObject var player: PlayerManager
    @EnvironmentObject var store: PlaylistStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Spacer(minLength: 0)
                ZStack {
                    VideoSurface(player: player.player)
                        .aspectRatio(16 / 9, contentMode: .fit)
                    if player.isBuffering && player.errorMessage == nil {
                        ProgressView(L10n.t("player.buffering")).tint(.white).foregroundStyle(.white)
                    }
                    if let err = player.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(.red)
                            Text(err).foregroundStyle(.white).multilineTextAlignment(.center)
                            Button(L10n.t("player.retry")) { player.retry() }
                                .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
                Spacer(minLength: 0)
                controls
            }
        }
        .foregroundStyle(.white)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down").font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44).background(.white.opacity(0.12), in: Circle())
            }
            .accessibilityLabel(L10n.t("player.close"))
            VStack(alignment: .leading, spacing: 2) {
                Text(player.current?.name ?? "").font(.headline).lineLimit(1)
                if let g = player.current?.group, !g.isEmpty {
                    Text(g.categoryDisplay).font(.caption).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                }
            }
            Spacer()
            if let c = player.current {
                Button { store.toggleFavorite(c) } label: {
                    Image(systemName: store.isFavorite(c) ? "heart.fill" : "heart")
                        .font(.title3).foregroundStyle(store.isFavorite(c) ? .red : .white)
                }
                .accessibilityLabel(L10n.t("common.favorite"))
            }
            AirPlayButton().frame(width: 34, height: 34)
        }
        .padding()
    }

    private var controls: some View {
        HStack(spacing: 46) {
            Button { player.previous() } label: { Image(systemName: "backward.fill").font(.title) }
                .accessibilityLabel(L10n.t("player.previous"))
            Button { player.togglePlay() } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
            }
            .accessibilityLabel(L10n.t(player.isPlaying ? "player.pause" : "player.play"))
            Button { player.next() } label: { Image(systemName: "forward.fill").font(.title) }
                .accessibilityLabel(L10n.t("player.next"))
        }
        .padding(.bottom, 40)
    }
}

/// AVPlayerViewController gives native fullscreen, Picture in Picture and AirPlay.
struct VideoSurface: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.allowsPictureInPicturePlayback = true
        vc.canStartPictureInPictureAutomaticallyFromInline = true
        vc.videoGravity = .resizeAspect
        vc.view.backgroundColor = .black
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        if vc.player !== player { vc.player = player }
    }
}
