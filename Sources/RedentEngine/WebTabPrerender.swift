import RedentKit
import WebKit

extension WebTab {
    /// Takes over the results page loaded while the user was typing.
    ///
    /// Only a tab with no live view takes one: a tab already showing a page
    /// would lose its whole back list to the swap.
    /// - Returns: whether the page stood in for loading `url`.
    func adoptPrerendered(_ url: URL) -> Bool {
        guard webView == nil, let controller else { return false }
        let store = controller.contexts.store(for: snapshot.browsingContext)
        let options = PageContentOptions(controller.settings)
        guard let view = controller.warmer.prerenderer.take(url, store: store, options: options) else {
            return false
        }
        install(view)
        navigationEvents.started()
        // The page loaded before anything observed it; KVO reports changes only.
        isLoading = view.isLoading
        progress = view.estimatedProgress
        canGoBack = view.canGoBack
        applyURL(view.url)
        if let title = view.title, !title.isEmpty { self.title = title }
        // A page that already finished never tells its new delegate so, and
        // history and the favicon both hang off that call.
        if !view.isLoading { navigationDelegate?.webView(view, didFinish: nil) }
        return true
    }
}
