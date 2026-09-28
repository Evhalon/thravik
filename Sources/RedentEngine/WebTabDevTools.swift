import Foundation

/// Chrome's DevTools, docked under this tab's page.
extension WebTab {
    public var isShowingDevTools: Bool { devToolsPanel != nil }

    public func toggleDevTools() {
        if isShowingDevTools { closeDevTools() } else { showDevTools() }
    }

    /// Opens the panel, or leaves it open. Needs a live page to inspect.
    func showDevTools() {
        guard devToolsPanel == nil, let webView, let panel = DevToolsPanel(inspecting: webView) else { return }
        panel.onClose = { [weak self, weak panel] in
            guard let self, self.devToolsPanel === panel else { return }
            self.devToolsPanel = nil
            self.applyPageZoom()
        }
        panel.onDeviceScaleChange = { [weak self] in self?.applyPageZoom() }
        panel.onOpenURL = { [weak self] in self?.controller?.newTab(url: $0) }
        devToolsPanel = panel
        panel.open()
    }

    func closeDevTools() {
        devToolsPanel?.close()
        devToolsPanel = nil
        applyPageZoom()
    }

    /// Device mode's own scale replaces the user's zoom while it lasts, so the
    /// emulated screen lays out at exactly the device's width in CSS pixels.
    func applyPageZoom() {
        webView?.pageZoom = devToolsPanel?.deviceScale ?? zoom
    }
}

extension TabController {
    public func toggleDevTools(_ id: UUID) {
        webTabs.first { $0.id == id }?.toggleDevTools()
    }

    public func isShowingDevTools(_ id: UUID) -> Bool {
        webTabs.first { $0.id == id }?.isShowingDevTools ?? false
    }
}
