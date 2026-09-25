import WebKit

/// Loads the results page for what the user is typing, so return shows a page
/// that is already there. A search takes about a second to finish loading;
/// preconnecting alone saves under a tenth of that.
///
/// One page at most, in a view built fresh for it: a view reused across
/// queries would carry every half-typed search in its back list. The page runs
/// with no delegate, so nothing it does reaches history, and with media
/// suspended, so an unseen page cannot make a sound.
@MainActor
final class SearchPrerenderer {
    private struct Page {
        let url: URL
        let view: WKWebView
        let store: ObjectIdentifier
        let options: PageContentOptions
    }

    /// A page nobody opened stops holding a web content process after this.
    private static let lifetime = Duration.seconds(30)

    private var page: Page?
    private var expiry: Task<Void, Never>?

    func prerender(_ url: URL, in view: WKWebView, store: WKWebsiteDataStore, options: PageContentOptions) {
        discard()
        view.setAllMediaPlaybackSuspended(true) {}
        BrowserUserAgent.apply(to: view, for: url)
        view.load(URLRequest(url: url))
        page = Page(url: url, view: view, store: ObjectIdentifier(store), options: options)
        expiry = Task { [weak self] in
            try? await Task.sleep(for: Self.lifetime)
            guard !Task.isCancelled else { return }
            self?.discard()
        }
    }

    func isPrerendering(_ url: URL, store: WKWebsiteDataStore, options: PageContentOptions) -> Bool {
        guard let page else { return false }
        return page.url == url && page.store == ObjectIdentifier(store) && page.options == options
    }

    /// - Returns: the page for `url`, when it was loaded for the same data store
    ///   and content options the tab would have used itself.
    func take(_ url: URL, store: WKWebsiteDataStore, options: PageContentOptions) -> WKWebView? {
        guard isPrerendering(url, store: store, options: options), let view = page?.view else { return nil }
        page = nil
        expiry?.cancel()
        view.setAllMediaPlaybackSuspended(false) {}
        return view
    }

    func refreshContent(_ contentBlocker: ContentBlocker?) {
        guard let page else { return }
        WebViewFactory.apply(page.options, contentBlocker: contentBlocker, on: page.view)
    }

    func discard() {
        expiry?.cancel()
        page?.view.stopLoading()
        page = nil
    }
}
