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
        var currentOffer: Offer?
        var detail = "Aștept oferta"
        if demo {
            currentOffer = Offer(price: 12.60, pickup: 0.4, trip: 3.4, totalMinutes: 9)
            detail = "DEMO"
        } else if SharedStore.file == nil {
            detail = "App Group indisponibil"
        } else if let snapshot = SharedStore.read(), Date().timeIntervalSince(snapshot.timestamp) < 3 {
            if let offer = snapshot.offer {
                currentOffer = offer
                detail = offer.totalMinutes == nil ? "Durata nu a fost citită complet" : "Ofertă detectată"
            } else { detail = snapshot.message }
        } else { detail = "Fără date recente · pornește captura" }
        if !wantsStart { status = detail }
        let width = 640, height = 400
        var optionalBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true, kCVPixelBufferIOSurfacePropertiesKey as String: [:]]
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attributes as CFDictionary, &optionalBuffer) == kCVReturnSuccess, let buffer = optionalBuffer else { return }
        CVPixelBufferLockBaseAddress(buffer, [])
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { CVPixelBufferUnlockBaseAddress(buffer, []); return }
        context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(context)
        UIColor(red: 0.07, green: 0.16, blue: 0.23, alpha: 1).setFill()
        context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .left
        func number(_ value: Double?, digits: Int = 2) -> String {
            guard let value, value.isFinite else { return "—" }
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "ro_RO")
            formatter.minimumFractionDigits = digits
            formatter.maximumFractionDigits = digits
            return formatter.string(from: NSNumber(value: value)) ?? "—"
        }
        func text(_ value: String, _ rect: CGRect, size: CGFloat, color: UIColor = .white, weight: UIFont.Weight = .semibold) {
            (value as NSString).draw(in: rect, withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight), .foregroundColor: color, .paragraphStyle: paragraph])
        }
        let muted = UIColor(red: 0.70, green: 0.80, blue: 0.87, alpha: 1)
        let yellow = UIColor(red: 0.97, green: 0.91, blue: 0.28, alpha: 1)
        text(number(currentOffer?.perKM) + " RON/km", CGRect(x: 28, y: 24, width: 584, height: 80), size: 57, color: yellow, weight: .bold)
        text(number(currentOffer?.perHour) + " RON/oră", CGRect(x: 28, y: 112, width: 584, height: 54), size: 37)
        for x in [CGFloat(28), CGFloat(330)] {
            UIColor(red: 0.15, green: 0.27, blue: 0.36, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: x, y: 186, width: 282, height: 154), cornerRadius: 18).fill()
        }
        text("Distanță totală", CGRect(x: 46, y: 204, width: 250, height: 32), size: 23, color: muted, weight: .medium)
        text(number(currentOffer?.totalDistance, digits: 1) + " km", CGRect(x: 46, y: 248, width: 250, height: 65), size: 43, weight: .bold)
        text("Durată totală", CGRect(x: 348, y: 204, width: 250, height: 32), size: 23, color: muted, weight: .medium)
        let minutes = currentOffer?.totalMinutes
        let durationDigits = minutes.map { $0.rounded() == $0 ? 0 : 1 } ?? 0
        text(number(minutes, digits: durationDigits) + " min", CGRect(x: 348, y: 248, width: 250, height: 65), size: 43, weight: .bold)
        // Keep operational status out of a valid live offer; label demo and
        // missing values so they cannot be mistaken for measured live results.
        if demo || currentOffer == nil || currentOffer?.totalMinutes == nil {
            text(detail, CGRect(x: 28, y: 355, width: 584, height: 36), size: 20, color: muted, weight: .medium)
        }
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
