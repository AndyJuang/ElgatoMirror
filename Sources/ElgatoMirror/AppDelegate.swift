import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var mirrorWindowController: MirrorWindowController?
    private var isEnabled = false
    private var sourceScreen: NSScreen?
    private var targetScreen: NSScreen?

    func applicationDidFinishLaunching(_ notification: Notification) {
        updateScreenDefaults()
        setupStatusItem()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func updateScreenDefaults() {
        let screens = NSScreen.screens
        sourceScreen = NSScreen.main ?? screens.first
        targetScreen = screens.first(where: { $0 != NSScreen.main }) ?? NSScreen.main
    }

    @objc private func screensChanged() {
        if isEnabled { disableMirror() }
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
        guard let src = sourceScreen, let tgt = targetScreen else {
            showAlert("請先選擇來源與目標螢幕。")
            return
        }

        mirrorWindowController = MirrorWindowController(sourceScreen: src, targetScreen: tgt)
        mirrorWindowController?.startMirroring { [weak self] success, errorMsg in
            DispatchQueue.main.async {
                if success {
                    self?.isEnabled = true
                    self?.updateStatusButton()
                    self?.updateMenu()
                } else {
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

    private func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "ElgatoMirror"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "確定")
        alert.runModal()
    }
}
