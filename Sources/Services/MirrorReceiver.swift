import UIKit
import ReplayKit

/// Receives screen frames from the broadcast extension (via the App Group)
/// and publishes them for the car screen.
@MainActor
final class MirrorReceiver: ObservableObject {
    static let shared = MirrorReceiver()
    static let extensionID = "com.ra7al.cartv.broadcast"

    @Published private(set) var frame: UIImage?
    @Published private(set) var active = false

    private var frameURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Brand.appGroup)?
            .appendingPathComponent("mirror-frame.jpg")
    }

    init() {
        observe("com.ra7al.cartv.mirror.started") { $0.setActive(true) }
        observe("com.ra7al.cartv.mirror.finished") { $0.setActive(false) }
        observe("com.ra7al.cartv.mirror.frame") { $0.loadFrame() }
    }

    private func setActive(_ on: Bool) {
        active = on
        CarState.shared.mirroring = on
        if !on { frame = nil }
    }

    private func loadFrame() {
        guard let url = frameURL, let data = try? Data(contentsOf: url), let img = UIImage(data: data) else { return }
        if !active { setActive(true) }
        frame = img
    }

    private func observe(_ name: String, _ handler: @escaping (MirrorReceiver) -> Void) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let box = Unmanaged.passRetained(HandlerBox { [weak self] in
            Task { @MainActor in if let self { handler(self) } }
        })
        CFNotificationCenterAddObserver(center, box.toOpaque(), { _, observer, _, _, _ in
            guard let observer else { return }
            Unmanaged<HandlerBox>.fromOpaque(observer).takeUnretainedValue().fire()
        }, name as CFString, nil, .deliverImmediately)
    }

    /// Opens the system "Start Broadcast" sheet with our extension preselected.
    static func showBroadcastPicker() {
        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        picker.preferredExtension = extensionID
        picker.showsMicrophoneButton = false
        picker.alpha = 0.01
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        window?.addSubview(picker)
        for case let button as UIButton in picker.subviews {
            button.sendActions(for: .touchUpInside)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { picker.removeFromSuperview() }
    }
}

private final class HandlerBox {
    let fire: () -> Void
    init(_ fire: @escaping () -> Void) { self.fire = fire }
}
