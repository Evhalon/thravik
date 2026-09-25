import Foundation
import RedentKit
import WebKit

extension WebTab {
    /// Releases the web view so its content process can exit, keeping
    /// `snapshot` intact. Idempotent.
    public func hibernate() {
        guard let view = webView else { return }
        let host = view.superview as? WebViewHost
        teardownObservers()
        view.configuration.userContentController.removeScriptMessageHandler(
            forName: PageScripts.messageHandlerName, contentWorld: PageScripts.contentWorld
        )
        signalRouter = nil
        view.stopLoading()
        view.navigationDelegate = nil
        view.uiDelegate = nil
        view.removeFromSuperview()
        host?.removeFromSuperview()
        navigationDelegate = nil
        webView = nil
        isHibernated = true
        // The items belong to the list that just went away; keeping them would
        // pin the whole back/forward chain and let the panel promise a restore
        // it can no longer perform.
        liveItems.removeAll()
        snapshot.timeline.dropLiveState()
        audibleFrames.removeAll()
        isPlayingAudio = false
    }

    /// Swaps the rule lists on an already-live view when settings change,
    /// without needing a reload.
    func applySettingsChange(_ options: PageContentOptions) {
        guard let webView else { return }
        WebViewFactory.apply(options, contentBlocker: controller?.contentBlocker, on: webView)
    }
}

extension TabController {
    /// Builds the spare web view ahead of the first navigation, so opening a
    /// tab does not pay for a content process launch on the main thread.
    public func warmUp() {
        warmer.prepare(store: contexts.store(for: spaceContext),
                       options: PageContentOptions(settings), contentBlocker: contentBlocker)
    }

    /// Warms the connection to where the address bar is about to go. A private
    /// window's handshakes must not run through the persistent profile.
    public func preconnect(to url: URL) {
        guard privateSessionID == nil, let scheme = url.scheme, scheme == "https" || scheme == "http",
              let host = url.host(), let selected = webTabs.first(where: { $0.id == selectedID })
        else { return }
        let port = url.port.map { ":\($0)" } ?? ""
        let store = contexts.store(for: selected.snapshot.browsingContext)
        warmer.preconnect(to: "\(scheme)://\(host)\(port)", store: store)
    }

    /// Hibernates every non-selected, non-pinned, silent tab whose snapshot has
    /// been idle past the current hibernation policy's threshold. `.off` (a
    /// `nil` threshold) does nothing. Music in a background tab is the tab in use.
    public func sweepHibernation(now: Date, keeping visible: Set<UUID>) {
        guard let threshold = settings.hibernationIdleThreshold else { return }
        let onScreen = visible.union([selectedID].compactMap { $0 })
        for tab in webTabs {
            if onScreen.contains(tab.id) {
                tab.snapshot.lastActiveAt = now
                continue
            }
            guard !tab.isPinned, !tab.isHibernated, !tab.isPlayingAudio else { continue }
            if now.timeIntervalSince(tab.snapshot.lastActiveAt) >= threshold {
                tab.hibernate()
            }
        }
    }

    /// Compilation finishes after the first tabs exist. Attach then, and
    /// drop the spare so the next wake is built with the list already on it.
    func installCompiledBlockList() {
        warmer.contentRulesChanged(contentBlocker)
        for tab in webTabs {
            tab.applySettingsChange(PageContentOptions(settings))
        }
        warmUp()
    }

    /// Idle is measured from last on-screen time, not from tab creation.
    func touchActivity(of id: UUID?, at now: Date = .now) {
        guard let id, let tab = webTabs.first(where: { $0.id == id }) else { return }
        tab.snapshot.lastActiveAt = now
    }
}
