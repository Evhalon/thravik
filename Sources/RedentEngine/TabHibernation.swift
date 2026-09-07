import Foundation
import RedentKit
import WebKit

extension WebTab {
    /// Releases the web view so its content process can exit, keeping
    /// `snapshot` intact. Idempotent.
    public func hibernate() {
        guard let view = webView else { return }
        teardownObservers()
        view.configuration.userContentController.removeScriptMessageHandler(
            forName: PageScripts.messageHandlerName, contentWorld: PageScripts.contentWorld
        )
        signalRouter = nil
        view.stopLoading()
        view.navigationDelegate = nil
        view.uiDelegate = nil
        view.removeFromSuperview()
        navigationDelegate = nil
        webView = nil
        isHibernated = true
        // The items belong to the list that just went away; keeping them would
        // pin the whole back/forward chain and let the panel promise a restore
        // it can no longer perform.
        liveItems.removeAll()
        snapshot.timeline.dropLiveState()
    }

    /// Toggles the built-in ad/tracker list on an already-live view when
    /// settings change, without needing a reload.
    func applySettingsChange(blocksTrackers: Bool) {
        guard let webView else { return }
        WebViewFactory.setContentBlocking(blocksTrackers, list: controller?.contentBlocker.compiledList, on: webView)
    }
}

extension TabController {
    /// Builds the spare web view ahead of the first navigation, so opening a
    /// tab does not pay for a content process launch on the main thread.
    public func warmUp() {
        let context = BrowsingContext.container(
            workspace.spaces.first { $0.id == workspace.selectedSpaceID }?.defaultContainerID
                ?? BrowserContainer.defaultID
        )
        warmer.prepare(store: contexts.store(for: context),
                       blocksTrackers: settings.blocksTrackers, contentBlocker: contentBlocker)
    }

    /// Hibernates every non-selected, non-pinned tab whose snapshot has been
    /// idle past the current hibernation policy's threshold. `.off` (a `nil`
    /// threshold) does nothing.
    public func sweepHibernation(now: Date, keeping visible: Set<UUID>) {
        guard let threshold = settings.hibernation.idleThreshold else { return }
        let onScreen = visible.union([selectedID].compactMap { $0 })
        for tab in webTabs {
            if onScreen.contains(tab.id) {
                tab.snapshot.lastActiveAt = now
                continue
            }
            guard !tab.isPinned, !tab.isHibernated else { continue }
            if now.timeIntervalSince(tab.snapshot.lastActiveAt) >= threshold {
                tab.hibernate()
            }
        }
    }

    /// Compilation finishes after the first tabs exist. Attach then, and
    /// drop the spare so the next wake is built with the list already on it.
    func installCompiledBlockList() {
        warmer.discard()
        for tab in webTabs {
            tab.applySettingsChange(blocksTrackers: settings.blocksTrackers)
        }
        warmUp()
    }

    /// Idle is measured from last on-screen time, not from tab creation.
    func touchActivity(of id: UUID?, at now: Date = .now) {
        guard let id, let tab = webTabs.first(where: { $0.id == id }) else { return }
        tab.snapshot.lastActiveAt = now
    }
}
