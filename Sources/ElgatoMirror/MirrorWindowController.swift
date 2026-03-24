import AppKit

class MirrorWindowController: NSObject {
    private let sourceScreen: NSScreen
    private let targetScreen: NSScreen
    private var mirrorWindow: NSWindow?
    private var mirrorView: MirrorView?
    private var captureManager: CaptureManager?
    var onMirroringStopped: (() -> Void)?

    init(sourceScreen: NSScreen, targetScreen: NSScreen) {
        self.sourceScreen = sourceScreen
        self.targetScreen = targetScreen
    }

    func startMirroring(completion: @escaping (Bool, String?) -> Void) {
        let view = createMirrorWindow()

        let sameScreen = (sourceScreen == targetScreen)
        let manager = CaptureManager()
        manager.onStreamStopped = { [weak self] in
            self?.stopMirroring()
            self?.onMirroringStopped?()
        }
        captureManager = manager

        Task {
            do {
                try await manager.startCapture(
                    sourceScreen: sourceScreen,
                    excludeOurApp: sameScreen
                ) { [weak self] image in
                    DispatchQueue.main.async {
                        self?.mirrorView?.display(image: image)
                    }
                }
                completion(true, nil)
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.mirrorWindow?.orderOut(nil)
                    self?.mirrorWindow = nil
                }
                completion(false, "螢幕擷取失敗：\(error.localizedDescription)\n\n請至「系統設定 > 隱私權與安全性 > 螢幕錄影」授予 ElgatoMirror 權限。")
            }
        }

        mirrorView = view
    }

    @discardableResult
    private func createMirrorWindow() -> MirrorView {
        let screenFrame = targetScreen.frame

        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        // Place above all normal app windows
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        window.backgroundColor = .black
        window.isOpaque = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.ignoresMouseEvents = true

        let view = MirrorView(frame: CGRect(origin: .zero, size: screenFrame.size))
        window.contentView = view
        window.setFrame(screenFrame, display: false)
        window.orderFrontRegardless()

        mirrorWindow = window
        return view
    }

    func stopMirroring() {
        let manager = captureManager
        captureManager = nil
        Task { await manager?.stopCapture() }

        DispatchQueue.main.async { [weak self] in
            self?.mirrorWindow?.orderOut(nil)
            self?.mirrorWindow?.close()
            self?.mirrorWindow = nil
            self?.mirrorView = nil
        }
    }
}
