import AVFoundation
import Combine
import MediaPlayer

@MainActor
final class PlayerManager: ObservableObject {
    static let shared = PlayerManager()

    let player = AVPlayer()
    @Published private(set) var current: Channel?
    @Published private(set) var queue: [Channel] = []
    @Published private(set) var isPlaying = false
    @Published private(set) var isBuffering = false
    @Published private(set) var errorMessage: String?

    private var statusObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?
    private var failObserver: NSObjectProtocol?

    init() {
        player.allowsExternalPlayback = true
        player.automaticallyWaitsToMinimizeStalling = true
        timeControlObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] p, _ in
            let status = p.timeControlStatus
            Task { @MainActor in
                self?.isPlaying = status == .playing
                self?.isBuffering = status == .waitingToPlayAtSpecifiedRate
            }
        }
        configureSession()
        configureRemoteCommands()
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func play(_ channel: Channel, queue: [Channel]? = nil) {
        if let queue { self.queue = queue }
        if !self.queue.contains(where: { $0.id == channel.id }) { self.queue = [channel] + self.queue }
        current = channel
        errorMessage = nil

        let item = AVPlayerItem(url: channel.url)
        item.preferredForwardBufferDuration = 5
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] it, _ in
            let failed = it.status == .failed
            let message = it.error?.localizedDescription
            Task { @MainActor in
                if failed { self?.errorMessage = message ?? L10n.t("player.failed") }
            }
        }
        if let failObserver { NotificationCenter.default.removeObserver(failObserver) }
        failObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.errorMessage = L10n.t("player.interrupted") }
        }

        player.replaceCurrentItem(with: item)
        player.play()
        PlaylistStore.shared.markWatched(channel)
        updateNowPlaying()
    }

    func togglePlay() {
        guard current != nil else { return }
        if player.timeControlStatus == .paused { player.play() } else { player.pause() }
        updateNowPlaying()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        current = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func next() { step(+1) }
    func previous() { step(-1) }

    func retry() {
        if let c = current { play(c) }
    }

    private func step(_ delta: Int) {
        guard !queue.isEmpty else { return }
        let index = current.flatMap { c in queue.firstIndex(where: { $0.id == c.id }) } ?? 0
        let next = (index + delta + queue.count) % queue.count
        play(queue[next])
    }

    private func configureRemoteCommands() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.player.play() }
            return .success
        }
        cc.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.player.pause() }
            return .success
        }
        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlay() }
            return .success
        }
        cc.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.next() }
            return .success
        }
        cc.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previous() }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let c = current else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: c.name,
            MPMediaItemPropertyArtist: c.group.isEmpty ? "RA7AL Car TV" : c.group,
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.video.rawValue
        ]
        info[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
