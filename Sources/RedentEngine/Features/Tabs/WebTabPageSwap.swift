import RedentKit
import WebKit

/// Back and Forward across the views a prerendered search stepped in front of.
/// The live view's own list always goes first: it holds the newer pages.
extension WebTab {
    /// Shows `view` in place of the live one, which stays reachable by Back.
    func displaceLiveView(with view: WKWebView) {
        if let current = detachLiveView() {
            current.pauseAllMediaPlayback {}
            release(displacedPages.displace(current))
        }
        install(view)
    }

    /// - Returns: whether Back stepped into a displaced view; `false` leaves
    ///   it to the live view's own list.
    func goBackToDisplacedPage() -> Bool {
        guard let current = webView, !current.canGoBack,
              let previous = displacedPages.stepBack(leaving: current) else { return false }
        step(from: current, to: previous)
        return true
    }

    func goForwardToDisplacedPage() -> Bool {
        guard let current = webView, !current.canGoForward,
              let next = displacedPages.stepForward(leaving: current) else { return false }
        step(from: current, to: next)
        return true
    }

    /// A main-frame navigation the live view is about to take. A new page
    /// there ends the forward path, as it does in WebKit's own list.
    func willNavigate(_ type: WKNavigationType) {
        timelineRecorder.willNavigate(type)
        guard type != .backForward, type != .reload else { return }
        release(displacedPages.clearForward())
        refreshHistoryAvailability()
    }

    /// Unhooks the live view from this tab without destroying it.
    @discardableResult
    func detachLiveView() -> WKWebView? {
        guard let view = webView else { return nil }
        stopFloatingVideo()
        canFloatVideo = false
        isVideoPlaying = false
        closeDevTools()
        teardownObservers()
        view.configuration.userContentController.removeScriptMessageHandler(
            forName: PageScripts.messageHandlerName, contentWorld: PageScripts.contentWorld
        )
        signalRouter = nil
        view.navigationDelegate = nil
        view.uiDelegate = nil
        navigationDelegate = nil
        webView = nil
        audibleFrames.removeAll()
        isPlayingAudio = false
        return view
    }

    /// Ends detached views and their content processes, along with the live
    /// items that would otherwise pin their whole back-forward lists.
    func release(_ views: [WKWebView]) {
        for view in views {
            let host = WebViewHost.containing(view)
            // Hosts and media presentations can outlive removal; stop playback
            // and prevent the page from restarting it while teardown finishes.
            view.setAllMediaPlaybackSuspended(true) {}
            view.closeAllMediaPresentations {}
            view.stopLoading()
            view.removeFromSuperview()
            host?.removeFromSuperview()
            let list = view.backForwardList
            let items = list.backList + list.forwardList + [list.currentItem].compactMap { $0 }
            liveItems = liveItems.filter { !items.contains($0.value) }
        }
    }

    /// Copies the state of a view that loaded before this tab observed it;
    /// KVO reports changes only.
    func mirrorState(of view: WKWebView) {
        isLoading = view.isLoading
        progress = view.estimatedProgress
        refreshHistoryAvailability()
        applyURL(view.url)
        if let title = view.title, !title.isEmpty { self.title = title }
    }

    func refreshHistoryAvailability() {
        canGoBack = (webView?.canGoBack ?? false) || displacedPages.canGoBack
        canGoForward = (webView?.canGoForward ?? false) || displacedPages.canGoForward
    }

    private func step(from current: WKWebView, to view: WKWebView) {
        detachLiveView()
        current.pauseAllMediaPlayback {}
        install(view)
        mirrorState(of: view)
        if let title = view.title { snapshot.title = title }
        guard !view.isLoading else { return }
        timelineRecorder.willNavigate(.backForward)
        timelineRecorder.finished(self, webView: view)
    }
}
