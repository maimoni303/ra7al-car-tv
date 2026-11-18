import ReplayKit
import CoreImage
import UIKit

/// Screen-broadcast extension: captures the iPhone screen and hands frames to the
/// main app through the shared App Group, so the app can show them on the car screen.
final class SampleHandler: RPBroadcastSampleHandler {
    private let group = "group.com.ra7al.cartv"
    private let ciContext = CIContext(options: [.cacheIntermediates: false])
    private var lastFrame = CFAbsoluteTimeGetCurrent()
    private let minInterval = 1.0 / 20.0     // up to 20 fps keeps memory under the 50 MB limit
    private let maxWidth: CGFloat = 1280

    private var frameURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
            .appendingPathComponent("mirror-frame.jpg")
    }

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        post("com.ra7al.cartv.mirror.started")
    }

    override func broadcastFinished() {
        post("com.ra7al.cartv.mirror.finished")
    }

    override func broadcastPaused() { post("com.ra7al.cartv.mirror.finished") }
    override func broadcastResumed() { post("com.ra7al.cartv.mirror.started") }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard sampleBufferType == .video else { return }
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastFrame >= minInterval else { return }
        lastFrame = now

        guard let pixel = CMSampleBufferGetImageBuffer(sampleBuffer), let url = frameURL else { return }
        autoreleasepool {
            var image = CIImage(cvPixelBuffer: pixel)
            if let orientationAttachment = CMGetAttachment(sampleBuffer,
                                                           key: RPVideoSampleOrientationKey as CFString,
                                                           attachmentModeOut: nil) as? NSNumber,
               let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value) {
                image = image.oriented(orientation)
            }
            let width = image.extent.width
            if width > maxWidth {
                let s = maxWidth / width
                image = image.transformed(by: CGAffineTransform(scaleX: s, y: s))
            }
            let space = CGColorSpaceCreateDeviceRGB()
            let options = [CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): 0.6]
            guard let data = ciContext.jpegRepresentation(of: image, colorSpace: space, options: options) else { return }
            try? data.write(to: url, options: .atomic)
            post("com.ra7al.cartv.mirror.frame")
        }
    }

    private func post(_ name: String) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                             CFNotificationName(name as CFString), nil, nil, true)
    }
}
