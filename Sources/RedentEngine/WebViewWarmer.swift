import WebKit

/// Keeps one web view built and its content process already running.
///
/// A tab's first navigation costs about 25ms of main-thread time, almost all of
/// it launching the web content process — which is why opening a tab used to
/// stutter. Evaluating a trivial script starts that process without navigating,
/// so the spare carries no back-forward entry the user could stumble back into.
///
/// Exactly one spare is kept. That is one idle process, paid deliberately: this
/// browser's whole argument is that memory is not free, so the pool does not
/// grow with the tab count.
@MainActor
final class WebViewWarmer {
    private struct Spare {
        let view: WKWebView
        let store: ObjectIdentifier
        let options: PageContentOptions
    }

    private var spare: Spare?
    /// The page return would show for the search being typed.
    let prerenderer = SearchPrerenderer()
    private var isPreparing = false
    private var preconnectedAt: [String: Date] = [:]

    /// - Returns: the primed view when it was built for the same data store and
    ///   content options; a mismatch means building fresh, never reusing a view
    ///   from another Container.
    func take(store: WKWebsiteDataStore, options: PageContentOptions) -> WKWebView? {
        guard let spare, spare.store == ObjectIdentifier(store),
              spare.options == options else { return nil }
        self.spare = nil
        return spare.view
    }

    /// Builds the next spare after a short pause, so the cost lands in the gap
    /// between actions rather than inside the one the user just took.
    func prepare(store: WKWebsiteDataStore, options: PageContentOptions, contentBlocker: ContentBlocker?) {
        guard spare == nil, !isPreparing else { return }
        isPreparing = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            self?.build(store: store, options: options, contentBlocker: contentBlocker)
        }
    }

    /// Opens the DNS, TCP and TLS handshakes to `origin` before the user presses
    /// return — the round trips Chromium browsers hide behind typing. The
    /// spare's network session is the one its data store's tabs load through,
    /// so the next navigation there finds the connection already open.
    func preconnect(to origin: String, store: WKWebsiteDataStore) {
        guard let spare, spare.store == ObjectIdentifier(store) else { return }
        let now = Date()
        // Browsers keep an idle connection for about a minute; asking sooner is noise.
        if let last = preconnectedAt[origin], now.timeIntervalSince(last) < 30 { return }
        if preconnectedAt.count > 32 { preconnectedAt.removeAll() }
        preconnectedAt[origin] = now
        spare.view.callAsyncJavaScript(
            Self.preconnectScript, arguments: ["origin": origin], in: nil, in: PageScripts.contentWorld
        ) { _ in }
    }

    private static let preconnectScript = """
    const link = document.createElement('link');
    link.rel = 'preconnect';
    link.href = origin;
    (document.head || document.documentElement).appendChild(link);
    """

    /// Releases the spare, any prerendered page, and their processes. Nothing
    /// on screen depends on either.
    func discard() {
        spare = nil
        prerenderer.discard()
    }

    /// The spare was built without the new rules and is cheap to build again;
    /// the prerendered page gets them in place, like a live tab.
    func contentRulesChanged(_ contentBlocker: ContentBlocker?) {
        spare = nil
        prerenderer.refreshContent(contentBlocker)
    }

    private func build(store: WKWebsiteDataStore, options: PageContentOptions, contentBlocker: ContentBlocker?) {
        isPreparing = false
        guard spare == nil else { return }
        let configuration = WebViewFactory.makeConfiguration(
            store: store, options: options, contentBlocker: contentBlocker
        )
        let view = WebViewFactory.makeWebView(configuration: configuration)
        view.evaluateJavaScript("0") { _, _ in }
        spare = Spare(view: view, store: ObjectIdentifier(store), options: options)
    }
}
