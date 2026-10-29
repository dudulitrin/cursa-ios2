import UIKit
import AVKit
import Combine

final class VideoView: UIView {
    override class var layerClass: AnyClass { AVSampleBufferDisplayLayer.self }
    var display: AVSampleBufferDisplayLayer { layer as! AVSampleBufferDisplayLayer }
}

final class PiPModel: NSObject, ObservableObject, AVPictureInPictureSampleBufferPlaybackDelegate, AVPictureInPictureControllerDelegate {
    let view = VideoView()
    @Published var status = "Pornește mai întâi testul PiP."
    var demo = true
    private var pip: AVPictureInPictureController?
    private var timer: Timer?
    private var possibleObservation: NSKeyValueObservation?
    private var wantsStart = false

    func setup() {
        guard pip == nil else { return }
        guard AVPictureInPictureController.isPictureInPictureSupported() else { status = "PiP nu este disponibil pe acest dispozitiv."; return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { status = "Sesiunea media nu a pornit: \(error.localizedDescription)"; return }
        view.display.videoGravity = .resizeAspect
        let source = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: view.display, playbackDelegate: self)
        pip = AVPictureInPictureController(contentSource: source)
        pip?.delegate = self
        pip?.requiresLinearPlayback = true
        possibleObservation = pip?.observe(\.isPictureInPicturePossible, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self, self.wantsStart, self.pip?.isPictureInPicturePossible == true else { return }
                self.wantsStart = false
                self.pip?.startPictureInPicture()
            }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in self?.render() }
        render()
    }
    func start() {
        setup()
        guard let pip else { return }
        render()
        if pip.isPictureInPicturePossible { pip.startPictureInPicture() }
        else { wantsStart = true; status = "Aștept inițializarea PiP. Dacă nu pornește, verifică setările PiP din iOS." }
    }
    func stop() { wantsStart = false; pip?.stopPictureInPicture() }
    func render() {
        var title = "— lei/km"
        var detail = "Aștept oferta"
        if demo {
            title = "3,32 lei/km"; detail = "DEMO · 12,60 lei / 3,8 km"
        } else if SharedStore.file == nil {
            detail = "App Group indisponibil"
        } else if let snapshot = SharedStore.read(), Date().timeIntervalSince(snapshot.timestamp) < 3 {
            if let offer = snapshot.offer {
                let formatter = NumberFormatter()
                formatter.locale = Locale(identifier: "ro_RO")
                formatter.minimumFractionDigits = 2; formatter.maximumFractionDigits = 2
                title = (formatter.string(from: NSNumber(value: offer.perKM)) ?? "—") + " lei/km"
                detail = "\(formatter.string(from: NSNumber(value: offer.price)) ?? "?") lei / \(formatter.string(from: NSNumber(value: offer.pickup + offer.trip)) ?? "?") km"
            } else { detail = snapshot.message }
        } else { detail = "Fără date recente · pornește captura" }
        if !wantsStart { status = detail }
        let width = 640, height = 360
        var optionalBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true, kCVPixelBufferIOSurfacePropertiesKey as String: [:]]
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attributes as CFDictionary, &optionalBuffer) == kCVReturnSuccess, let buffer = optionalBuffer else { return }
        CVPixelBufferLockBaseAddress(buffer, [])
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { CVPixelBufferUnlockBaseAddress(buffer, []); return }
        context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(context)
        UIColor(red: 0.08, green: 0.19, blue: 0.14, alpha: 1).setFill()
        context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
        (title as NSString).draw(in: CGRect(x: 15, y: 105, width: 610, height: 90), withAttributes: [.font: UIFont.systemFont(ofSize: 64, weight: .bold), .foregroundColor: UIColor(red: 0.84, green: 0.95, blue: 0.60, alpha: 1), .paragraphStyle: paragraph])
        (detail as NSString).draw(in: CGRect(x: 20, y: 210, width: 600, height: 100), withAttributes: [.font: UIFont.systemFont(ofSize: 23, weight: .medium), .foregroundColor: UIColor.white, .paragraphStyle: paragraph])
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(buffer, [])
        var description: CMVideoFormatDescription?
        guard CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: buffer, formatDescriptionOut: &description) == noErr, let description else { return }
        var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 4), presentationTimeStamp: CMTime(seconds: ProcessInfo.processInfo.systemUptime, preferredTimescale: 600), decodeTimeStamp: .invalid)
        var sample: CMSampleBuffer?
        guard CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: buffer, formatDescription: description, sampleTiming: &timing, sampleBufferOut: &sample) == noErr, let sample else { return }
        if let array = CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: true) {
            let entry = unsafeBitCast(CFArrayGetValueAtIndex(array, 0), to: CFMutableDictionary.self)
            CFDictionarySetValue(entry, Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(), Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        }
        if view.display.status == .failed { view.display.flush() }
        if view.display.isReadyForMoreMediaData { view.display.enqueue(sample) }
    }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {}
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange { CMTimeRange(start: .zero, duration: .positiveInfinity) }
    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool { false }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) { completionHandler() }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) { status = "PiP: \(error.localizedDescription)" }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) { completionHandler(true) }
    deinit { timer?.invalidate() }
}
