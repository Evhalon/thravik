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
        let blocksTrackers: Bool
    }

    private var spare: Spare?
    private var isPreparing = false

    /// - Returns: the primed view when it was built for the same data store and
    ///   blocking setting; a mismatch means building fresh, never reusing a view
    ///   from another Container.
    func take(store: WKWebsiteDataStore, blocksTrackers: Bool) -> WKWebView? {
        guard let spare, spare.store == ObjectIdentifier(store),
              spare.blocksTrackers == blocksTrackers else { return nil }
        self.spare = nil
        return spare.view
    }

    /// Builds the next spare after a short pause, so the cost lands in the gap
    /// between actions rather than inside the one the user just took.
    func prepare(store: WKWebsiteDataStore, blocksTrackers: Bool, contentBlocker: ContentBlocker?) {
        guard spare == nil, !isPreparing else { return }
        isPreparing = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            self?.build(store: store, blocksTrackers: blocksTrackers, contentBlocker: contentBlocker)
        }
    }

    /// Releases the spare and its process. Nothing on screen depends on it.
    func discard() {
        spare = nil
    }

    private func build(store: WKWebsiteDataStore, blocksTrackers: Bool, contentBlocker: ContentBlocker?) {
        isPreparing = false
        guard spare == nil else { return }
        let configuration = WebViewFactory.makeConfiguration(
            store: store, blocksTrackers: blocksTrackers, contentBlocker: contentBlocker
        )
        let view = WebViewFactory.makeWebView(configuration: configuration)
        view.evaluateJavaScript("0") { _, _ in }
        spare = Spare(view: view, store: ObjectIdentifier(store), blocksTrackers: blocksTrackers)
    }
}
