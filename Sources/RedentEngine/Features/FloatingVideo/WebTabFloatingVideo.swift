import AppKit
import RedentKit
import WebKit

extension WebTab {
    @discardableResult
    public func toggleFloatingVideo() async -> Bool {
        if isVideoFloating { returnVideoToTab(); return true }
        guard !floatingVideoOpening else { return true }
        guard canFloatVideo, let view = webView else { return false }
        floatingVideoOpening = true
        defer { floatingVideoOpening = false }
        floatingVideoRequestID &+= 1
        let request = floatingVideoRequestID
        let opened = try? await view.callAsyncJavaScript(
            "if (!window.redentFloatVideo?.open()) return null; return window.redentFloatVideo.sourceBounds()",
            in: nil, contentWorld: PageScripts.contentWorld
        )
        guard request == floatingVideoRequestID, webView === view, !isHibernated else {
            if webView === view, !isVideoFloating {
                view.evaluateJavaScript("window.redentFloatVideo?.restore()", in: nil,
                                        in: PageScripts.contentWorld) { _ in }
            }
            return false
        }
        guard let bounds = opened as? [String: Any] else { return false }
        controller?.videoPresentation.activeTab?.stopFloatingVideo()
        closeDevTools()
        let source = FloatingVideoSource(bounds: bounds, view: view)
        let panel = FloatingVideoPanel(view: view, aspectRatio: videoAspectRatio)
        panel.onDismiss = { [weak self] in self?.closeFloatingVideo() }
        panel.onReturn = { [weak self] in self?.returnVideoToTab() }
        if let controls = controller?.videoPresentation.makeControls?(self) { panel.installControls(controls) }
        floatingVideoPanel = panel
        controller?.videoPresentation.activeTab = self
        isVideoFloating = true
        await panel.present(from: source)
        return isVideoFloating && floatingVideoPanel === panel
    }

    public func returnVideoToTab() {
        guard let panel = floatingVideoPanel else { return }
        panel.focusSource()
        controller?.select(id)
        panel.returnToSource { [weak self, weak panel] in
            guard let self, self.floatingVideoPanel === panel else { return }
            self.stopFloatingVideo()
        }
    }

    public func closeFloatingVideo() {
        webView?.evaluateJavaScript(
            "window.redentFloatVideo?.pause()", in: nil, in: PageScripts.contentWorld
        ) { _ in }
        stopFloatingVideo()
    }

    public func toggleVideoPlayback() async {
        guard let webView else { return }
        _ = try? await webView.callAsyncJavaScript(
            "return window.redentFloatVideo?.toggle()", in: nil, contentWorld: PageScripts.contentWorld
        )
    }

    func stopFloatingVideo() {
        floatingVideoRequestID &+= 1
        guard let panel = floatingVideoPanel else { return }
        floatingVideoPanel = nil
        isVideoFloating = false
        if controller?.videoPresentation.activeTab === self { controller?.videoPresentation.activeTab = nil }
        panel.restore()
        webView?.evaluateJavaScript(
            "window.redentFloatVideo?.restore()", in: nil, in: PageScripts.contentWorld
        ) { _ in }
    }

    func receiveVideoState(_ state: [String: Any]) {
        guard let available = state["available"] as? Bool, let playing = state["playing"] as? Bool,
              let aspect = state["aspect"] as? Double, aspect.isFinite else { return }
        canFloatVideo = available
        isVideoPlaying = playing
        videoAspectRatio = min(max(aspect, 0.4), 3)
        receiveVideoPlayback(state)
        if !available { stopFloatingVideo() }
    }
}
