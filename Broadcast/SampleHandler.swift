import ReplayKit
import Vision
import ImageIO

final class SampleHandler: RPBroadcastSampleHandler {
    private var lastScan = -Double.infinity
    private var candidate: Offer?
    private var count = 0
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        guard SharedStore.file != nil else {
            finishBroadcastWithError(NSError(domain: "Cursa", code: 1, userInfo: [NSLocalizedDescriptionKey: "App Group indisponibil. Semnarea trebuie să păstreze același App Group în aplicație și extensie."]))
            return
        }
        SharedStore.write(nil, message: "Aștept oferta Bolt")
    }
    override func broadcastPaused() { candidate = nil; count = 0; SharedStore.write(nil, message: "Captură întreruptă") }
    override func broadcastFinished() { SharedStore.write(nil, message: "Captură oprită") }
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with type: RPSampleBufferType) {
        guard type == .video else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastScan >= 0.25 else { return }
        lastScan = now
        autoreleasepool {
            guard let image = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let raw = CMGetAttachment(sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) as? NSNumber
            let orientation = CGImagePropertyOrientation(rawValue: raw?.uint32Value ?? 1) ?? .up
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            // Crop the OCR work itself, rather than scanning the map and
            // discarding its text afterwards. Vision uses a lower-left origin.
            request.regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 0.55)
            do {
                try VNImageRequestHandler(cvPixelBuffer: image, orientation: orientation, options: [:]).perform([request])
                // Restrict to lower offer card. Never persist images, names, or addresses.
                let lines = (request.results ?? []).sorted { $0.boundingBox.midY > $1.boundingBox.midY }.compactMap { $0.topCandidates(1).first?.string }
                guard let offer = OfferParser.parse(lines.joined(separator: "\n")) else {
                    candidate = nil; count = 0
                    SharedStore.write(nil, message: "Aștept o ofertă clară")
                    return
                }
                count = candidate == offer ? min(count + 1, 2) : 1
                candidate = offer
                SharedStore.write(count >= 2 ? offer : nil, message: count >= 2 ? "Ofertă detectată" : "Verific cifrele…")
            } catch {
                candidate = nil; count = 0
                SharedStore.write(nil, message: "Nu pot citi imaginea")
            }
        }
    }
}

