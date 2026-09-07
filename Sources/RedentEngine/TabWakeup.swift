import Foundation
import RedentKit
import WebKit

extension WebTab {
    /// Builds a live web view for this tab if one doesn't already exist. If
    /// `url` is given and the tab is already awake, just navigates.
    func wake(loading url: URL?) {
        snapshot.lastActiveAt = .now
        guard webView == nil else {
            if let url, let webView { navigate(url, in: webView) }
            return
        }
        let view = makeWebView()
        install(view)
        if let target = url ?? snapshot.url {
            navigate(target, in: view)
        }
    }

    /// Takes over the view WebKit built for a window the page opened. Nothing
    /// is loaded here: that view already carries its opener link and the
    /// request WebKit is about to run, and re-loading the URL ourselves is
    /// exactly what would break a sign-in popup reporting back to its opener.
    func adopt(_ view: WKWebView) {
        snapshot.lastActiveAt = .now
        guard webView == nil else { return }
        install(view)
    }

    /// Called when `WebContentView` appears for a tab that has no live view.
    func wakeIfNeeded() {
        guard webView == nil else { return }
        wake(loading: nil)
    }

    func navigate(_ url: URL, in view: WKWebView) {
        BrowserUserAgent.apply(to: view, for: url)
        view.load(URLRequest(url: url))
    }

    /// Takes the warm spare when it was built for this tab's own data store,
    /// and leaves a fresh one warming for whoever needs it next.
    private func makeWebView() -> WKWebView {
        let store = controller?.contexts.store(for: snapshot.browsingContext) ?? .nonPersistent()
        let blocksTrackers = controller?.settings.blocksTrackers ?? true
        let blocker = controller?.contentBlocker
        defer { controller?.warmer.prepare(store: store, blocksTrackers: blocksTrackers, contentBlocker: blocker) }
        if let warm = controller?.warmer.take(store: store, blocksTrackers: blocksTrackers) { return warm }
        return WebViewFactory.makeWebView(configuration: WebViewFactory.makeConfiguration(
            store: store, blocksTrackers: blocksTrackers, contentBlocker: blocker
        ))
    }

    /// Wires a view — however it was built — to this tab.
    private func install(_ view: WKWebView) {
        let delegate = WebTabNavigationDelegate(tab: self)
        view.navigationDelegate = delegate
        view.uiDelegate = delegate
        navigationDelegate = delegate

        let router = PageSignalRouter(tab: self)
        view.configuration.userContentController.add(
            router, contentWorld: PageScripts.contentWorld, name: PageScripts.messageHandlerName
        )
        signalRouter = router

        webView = view
        isHibernated = false
        setupObservers(on: view)
    }
}
