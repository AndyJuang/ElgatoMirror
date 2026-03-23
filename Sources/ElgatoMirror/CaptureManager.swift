import ScreenCaptureKit
import AppKit
import CoreImage
import CoreMedia

class CaptureManager: NSObject, SCStreamOutput, SCStreamDelegate {
    private var stream: SCStream?
    private var frameCallback: ((CGImage) -> Void)?

    // Reuse CIContext across frames for performance
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    /// Start capturing `sourceScreen`. If `excludeOurApp` is true, removes our own
    /// overlay window from the capture (needed when source == target display).
    func startCapture(
        sourceScreen: NSScreen,
        excludeOurApp: Bool,
        frameCallback: @escaping (CGImage) -> Void
    ) async throws {
        self.frameCallback = frameCallback

        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

        let displayID = sourceScreen.displayID
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw CaptureError.displayNotFound
        }

        let filter: SCContentFilter
        if excludeOurApp,
           let ourApp = content.applications.first(where: {
               $0.bundleIdentifier == (Bundle.main.bundleIdentifier ?? "com.zhuangzheyun.ElgatoMirror")
           }) {
            filter = SCContentFilter(display: display, excludingApplications: [ourApp], exceptingWindows: [])
        } else {
            filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        }

        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.queueDepth = 3
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true

        let captureStream = SCStream(filter: filter, configuration: config, delegate: self)
        try captureStream.addStreamOutput(
            self,
            type: .screen,
            sampleHandlerQueue: .global(qos: .userInteractive)
        )
        try await captureStream.startCapture()
        self.stream = captureStream
    }

    func stopCapture() async {
        try? await stream?.stopCapture()
        stream = nil
        frameCallback = nil
    }

    // MARK: - SCStreamOutput

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen,
              sampleBuffer.isValid,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        frameCallback?(cgImage)
    }

    // MARK: - SCStreamDelegate

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("[CaptureManager] stream stopped: \(error)")
    }
}

enum CaptureError: LocalizedError {
    case displayNotFound

    var errorDescription: String? {
        switch self {
        case .displayNotFound:
            return "找不到對應的螢幕，請重新選擇來源螢幕。"
        }
    }
}
