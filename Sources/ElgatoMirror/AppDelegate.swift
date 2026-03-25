import AppKit
import ScreenCaptureKit
import CoreGraphics

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var mirrorWindowController: MirrorWindowController?
    private var isEnabled = false
    private var sourceScreen: NSScreen?
    private var targetScreen: NSScreen?
    private var globalKeyMonitor: Any?
    private var lastScreenCount: Int = 0
    /// nil = preflight 進行中；true = 已授權；false = 已拒絕
    private var screenCapturePermission: Bool? = nil

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.rotate()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        Logger.log("=== ElgatoMirror \(version) (\(build)) launched — macOS \(ProcessInfo.processInfo.operatingSystemVersionString) ===")
        Logger.log("Screens at launch: \(NSScreen.screens.map { "\($0.localizedName) id=\($0.displayID)" })")

        lastScreenCount = NSScreen.screens.count
        updateScreenDefaults()
        setupStatusItem()
        setupGlobalHotkey()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        preflightScreenCapturePermission()
    }

    /// 啟動時主動觸發 SCKit 權限流程。
    /// macOS 14+ 使用「螢幕與系統錄音」新模型，必須讓 SCKit 自己走過一次授權，
    /// 單靠在系統設定手動開啟 toggle 不足以讓正在執行的 process 取得權限。
    private func preflightScreenCapturePermission() {
        // CoreGraphics 層診斷（System Settings toggle 控制的是這層）
        let cgPreflight = CGPreflightScreenCaptureAccess()
        Logger.log("Preflight: CGPreflightScreenCaptureAccess=\(cgPreflight)")
        if !cgPreflight {
            let cgResult = CGRequestScreenCaptureAccess()
            Logger.log("Preflight: CGRequestScreenCaptureAccess result=\(cgResult)")
        }

        // SCKit 層
        Logger.log("Preflight: requesting SCShareableContent permission...")
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                screenCapturePermission = true
                Logger.log("Preflight: SCKit granted. displays=\(content.displays.map { "id=\($0.displayID) \($0.width)x\($0.height)" })")
            } catch {
                screenCapturePermission = false
                Logger.logError(error, context: "Preflight SCKit")
            }
            updateMenu()
        }
    }

    private func setupGlobalHotkey() {
        // ⌘⌥M：緊急停用鏡像（即使視窗擋住也能觸發）
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isEnabled else { return }
            let cmdOpt = NSEvent.ModifierFlags([.command, .option])
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == cmdOpt,
               event.charactersIgnoringModifiers?.lowercased() == "m" {
                DispatchQueue.main.async { self.disableMirror() }
            }
        }
    }

    private func updateScreenDefaults() {
        let screens = NSScreen.screens
        sourceScreen = NSScreen.main ?? screens.first
        targetScreen = screens.first(where: { $0 != NSScreen.main }) ?? NSScreen.main
    }

    @objc private func screensChanged() {
        let currentCount = NSScreen.screens.count
        if currentCount != lastScreenCount {
            lastScreenCount = currentCount
            if isEnabled { disableMirror() }
        }
        updateScreenDefaults()
        updateMenu()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateStatusButton()
        updateMenu()
    }

    private func updateStatusButton() {
        guard let button = statusItem?.button else { return }
        let name = isEnabled ? "rectangle.lefthalf.filled" : "rectangle.lefthalf.inset.filled"
        button.image = NSImage(systemSymbolName: name, accessibilityDescription: "ElgatoMirror")
        button.toolTip = isEnabled ? "鏡像已啟用 — 點選選單" : "鏡像已停用 — 點選選單"
    }

    func updateMenu() {
        let menu = NSMenu()
        let screens = NSScreen.screens

        // Status label
        let statusLabel = NSMenuItem(
            title: isEnabled ? "✓  鏡像已啟用" : "●  鏡像已停用",
            action: nil,
            keyEquivalent: ""
        )
        statusLabel.isEnabled = false
        menu.addItem(statusLabel)
        menu.addItem(.separator())

        // Source screen submenu
        let srcMenu = NSMenu()
        for (i, s) in screens.enumerated() {
            let item = NSMenuItem(
                title: screenLabel(s, index: i),
                action: #selector(selectSource(_:)),
                keyEquivalent: ""
            )
            item.representedObject = s
            item.state = (s == sourceScreen) ? .on : .off
            item.target = self
            srcMenu.addItem(item)
        }
        let srcItem = NSMenuItem(title: "來源螢幕", action: nil, keyEquivalent: "")
        srcItem.submenu = srcMenu
        menu.addItem(srcItem)

        // Target screen submenu
        let tgtMenu = NSMenu()
        for (i, s) in screens.enumerated() {
            let item = NSMenuItem(
                title: screenLabel(s, index: i),
                action: #selector(selectTarget(_:)),
                keyEquivalent: ""
            )
            item.representedObject = s
            item.state = (s == targetScreen) ? .on : .off
            item.target = self
            tgtMenu.addItem(item)
        }
        let tgtItem = NSMenuItem(title: "目標螢幕（題詞機）", action: nil, keyEquivalent: "")
        tgtItem.submenu = tgtMenu
        menu.addItem(tgtItem)

        menu.addItem(.separator())

        let toggleItem = NSMenuItem(
            title: isEnabled ? "停用鏡像" : "啟用鏡像",
            action: #selector(toggleMirror),
            keyEquivalent: "m"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(
            title: "關於 ElgatoMirror",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "結束 ElgatoMirror",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func screenLabel(_ screen: NSScreen, index: Int) -> String {
        if screen == NSScreen.main {
            return "主螢幕（\(screen.localizedName)）"
        }
        return "外接螢幕 \(index)（\(screen.localizedName)）"
    }

    // MARK: - Actions

    @objc private func selectSource(_ sender: NSMenuItem) {
        guard let screen = sender.representedObject as? NSScreen else { return }
        sourceScreen = screen
        if isEnabled { disableMirror(); enableMirror() }
        updateMenu()
    }

    @objc private func selectTarget(_ sender: NSMenuItem) {
        guard let screen = sender.representedObject as? NSScreen else { return }
        targetScreen = screen
        if isEnabled { disableMirror(); enableMirror() }
        updateMenu()
    }

    @objc private func toggleMirror() {
        isEnabled ? disableMirror() : enableMirror()
    }

    // MARK: - Mirror control

    private func enableMirror() {
        switch screenCapturePermission {
        case nil:
            Logger.log("enableMirror: blocked — permission still pending")
            showAlert("正在等待系統授權。\n\n請在剛才彈出的對話框中點選「打開系統設定」，於「螢幕與系統錄音」中開啟 ElgatoMirror 的權限後，重新啟動 App 再試一次。")
            return
        case false:
            Logger.log("enableMirror: blocked — permission denied")
            showAlert("螢幕擷取權限已被拒絕。\n\n請至「系統設定 > 隱私權與安全性 > 螢幕與系統錄音」開啟 ElgatoMirror 的權限後，重新啟動 App 再試一次。")
            return
        default:
            break
        }

        guard let src = sourceScreen, let tgt = targetScreen else {
            Logger.log("enableMirror: blocked — sourceScreen or targetScreen is nil")
            showAlert("請先選擇來源與目標螢幕。")
            return
        }

        Logger.log("enableMirror: src=\(src.localizedName) id=\(src.displayID)  tgt=\(tgt.localizedName) id=\(tgt.displayID)")
        let controller = MirrorWindowController(sourceScreen: src, targetScreen: tgt)
        controller.onMirroringStopped = { [weak self] in
            self?.disableMirror()
        }
        mirrorWindowController = controller
        controller.startMirroring { [weak self] success, errorMsg in
            DispatchQueue.main.async {
                if success {
                    Logger.log("enableMirror: mirroring started successfully")
                    self?.isEnabled = true
                    self?.updateStatusButton()
                    self?.updateMenu()
                } else {
                    Logger.log("enableMirror: mirroring failed — \(errorMsg ?? "nil")")
                    self?.mirrorWindowController = nil
                    let msg = errorMsg ?? "未知錯誤。請至「系統設定 > 隱私權與安全性 > 螢幕錄影」授予 ElgatoMirror 權限。"
                    self?.showAlert(msg)
                }
            }
        }
    }

    private func disableMirror() {
        mirrorWindowController?.stopMirroring()
        mirrorWindowController = nil
        isEnabled = false
        updateStatusButton()
        updateMenu()
    }

    @objc private func showAbout() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let alert = NSAlert()
        alert.messageText = "ElgatoMirror"
        alert.informativeText = "版本 \(version) (\(build))\n\n將螢幕畫面水平鏡像顯示到 Elgato Prompter 題詞機的選單列工具。\n\n© 2025 Andy Juang"
        alert.alertStyle = .informational
        if let icon = NSImage(named: "AppIcon") {
            alert.icon = icon
        }
        alert.addButton(withTitle: "確定")
        alert.runModal()
    }

    private func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "ElgatoMirror"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "確定")
        alert.runModal()
    }
}
