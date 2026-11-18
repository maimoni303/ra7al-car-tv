import CarPlay
import AVFoundation
import UIKit
import Combine

/// CarPlay scene.
/// • With the CarPlay navigation entitlement, CarPlay hands us a `CPWindow`; we draw the
///   current channel (or the mirrored iPhone screen) in it, under a map template whose
///   buttons control playback.
/// • Without a window, we fall back to list templates for browsing channels.
@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var carWindow: CPWindow?
    private var mapTemplate: CPMapTemplate?
    private var cancellables = Set<AnyCancellable>()

    // MARK: Connection with a drawable window (navigation-style apps)

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController,
                                  to window: CPWindow) {
        self.interfaceController = interfaceController
        carWindow = window
        window.rootViewController = CarVideoViewController()

        let map = CPMapTemplate()
        map.automaticallyHidesNavigationBar = false
        map.leadingNavigationBarButtons = [
            CPBarButton(title: L10n.t("car.channels")) { [weak self] _ in self?.showRoot() }
        ]
        map.trailingNavigationBarButtons = [
            CPBarButton(title: L10n.t("car.favorites")) { [weak self] _ in self?.showFavorites() }
        ]
        map.mapButtons = [
            mapButton("backward.fill") { PlayerManager.shared.previous() },
            mapButton("playpause.fill") { PlayerManager.shared.togglePlay() },
            mapButton("forward.fill") { PlayerManager.shared.next() }
        ]
        mapTemplate = map
        interfaceController.setRootTemplate(map, animated: true, completion: nil)

        CarState.shared.connected = true
        CarState.shared.videoWindowAvailable = true
        observeState()
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController,
                                  from window: CPWindow) {
        teardown()
    }

    // MARK: Connection without a window (list-only fallback)

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        CarState.shared.connected = true
        CarState.shared.videoWindowAvailable = false
        interfaceController.setRootTemplate(rootTabs(), animated: true, completion: nil)
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        teardown()
    }

    private func teardown() {
        interfaceController = nil
        carWindow = nil
        mapTemplate = nil
        cancellables.removeAll()
        CarState.shared.connected = false
        CarState.shared.videoWindowAvailable = false
    }

    private func observeState() {
        PlayerManager.shared.$current
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshVideoController() }
            .store(in: &cancellables)
        MirrorReceiver.shared.$active
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshVideoController() }
            .store(in: &cancellables)
    }

    private func refreshVideoController() {
        (carWindow?.rootViewController as? CarVideoViewController)?.refresh()
    }

    // MARK: Templates

    private func mapButton(_ symbol: String, action: @escaping @MainActor () -> Void) -> CPMapButton {
        let b = CPMapButton { _ in Task { @MainActor in action() } }
        b.image = UIImage(systemName: symbol)
        return b
    }

    private func rootTabs() -> CPTabBarTemplate {
        let channels = categoriesTemplate()
        channels.tabImage = UIImage(systemName: "tv")
        let favs = channelListTemplate(title: L10n.t("car.favorites"), channels: PlaylistStore.shared.favoriteChannels)
        favs.tabImage = UIImage(systemName: "heart")
        let recents = channelListTemplate(title: L10n.t("fav.recent"), channels: PlaylistStore.shared.recentChannels)
        recents.tabImage = UIImage(systemName: "clock")
        return CPTabBarTemplate(templates: [channels, favs, recents])
    }

    private func showRoot() {
        interfaceController?.pushTemplate(categoriesTemplate(), animated: true, completion: nil)
    }

    private func showFavorites() {
        let t = channelListTemplate(title: L10n.t("car.favorites"), channels: PlaylistStore.shared.favoriteChannels)
        interfaceController?.pushTemplate(t, animated: true, completion: nil)
    }

    private func categoriesTemplate() -> CPListTemplate {
        let groups = PlaylistStore.shared.grouped
        let limit = CPListTemplate.maximumItemCount
        let items: [CPListItem] = groups.prefix(limit).map { g in
            let item = CPListItem(text: g.name, detailText: "\(g.channels.count) \(L10n.t("home.channels"))")
            item.accessoryType = .disclosureIndicator
            item.handler = { [weak self] _, completion in
                guard let self else { completion(); return }
                let t = self.channelListTemplate(title: g.name, channels: g.channels)
                self.interfaceController?.pushTemplate(t, animated: true, completion: nil)
                completion()
            }
            return item
        }
        return CPListTemplate(title: L10n.t("car.channels"), sections: [CPListSection(items: items)])
    }

    private func channelListTemplate(title: String, channels: [Channel]) -> CPListTemplate {
        let limit = CPListTemplate.maximumItemCount
        let items: [CPListItem] = channels.prefix(limit).map { ch in
            let item = CPListItem(text: ch.name, detailText: ch.group.isEmpty ? nil : ch.group.categoryDisplay,
                                  image: UIImage(systemName: "play.tv"))
            item.handler = { [weak self] _, completion in
                PlayerManager.shared.play(ch, queue: channels)
                self?.loadLogo(for: item, channel: ch)
                if let self, self.mapTemplate != nil {
                    self.interfaceController?.popToRootTemplate(animated: true, completion: nil)
                } else {
                    self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
                }
                completion()
            }
            loadLogo(for: item, channel: ch)
            return item
        }
        let t = CPListTemplate(title: title, sections: [CPListSection(items: items)])
        if items.isEmpty {
            t.emptyViewTitleVariants = [L10n.t("car.empty")]
        }
        return t
    }

    private func loadLogo(for item: CPListItem, channel: Channel) {
        guard let url = channel.logo else { return }
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let img = UIImage(data: data) else { return }
            item.setImage(img)
        }
    }
}

/// Root view controller of the CarPlay window: shows the playing channel or the mirrored screen.
@MainActor
final class CarVideoViewController: UIViewController {
    private let playerLayer = AVPlayerLayerView()
    private let mirrorView = UIImageView()
    private let titleLabel = UILabel()
    private let hintLabel = UILabel()
    private var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        playerLayer.translatesAutoresizingMaskIntoConstraints = false
        mirrorView.translatesAutoresizingMaskIntoConstraints = false
        mirrorView.contentMode = .scaleAspectFit
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.textColor = UIColor(white: 1, alpha: 0.7)
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center
        hintLabel.font = .systemFont(ofSize: 17, weight: .medium)

        [playerLayer, mirrorView, titleLabel, hintLabel].forEach(view.addSubview)
        NSLayoutConstraint.activate([
            playerLayer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerLayer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerLayer.topAnchor.constraint(equalTo: view.topAnchor),
            playerLayer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mirrorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mirrorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mirrorView.topAnchor.constraint(equalTo: view.topAnchor),
            mirrorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hintLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8)
        ])
        playerLayer.player = PlayerManager.shared.player

        cancellable = MirrorReceiver.shared.$frame
            .receive(on: RunLoop.main)
            .sink { [weak self] img in self?.mirrorView.image = img }
        refresh()
    }

    func refresh() {
        let mirroring = MirrorReceiver.shared.active
        let current = PlayerManager.shared.current
        mirrorView.isHidden = !mirroring
        playerLayer.isHidden = mirroring || current == nil
        titleLabel.text = mirroring ? nil : current?.name
        hintLabel.isHidden = mirroring || current != nil
        hintLabel.text = L10n.t("car.hint")
    }
}

/// UIView backed by an AVPlayerLayer.
final class AVPlayerLayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var player: AVPlayer? {
        get { (layer as? AVPlayerLayer)?.player }
        set {
            (layer as? AVPlayerLayer)?.player = newValue
            (layer as? AVPlayerLayer)?.videoGravity = .resizeAspect
        }
    }
}
