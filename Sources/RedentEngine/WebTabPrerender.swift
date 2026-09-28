import RedentKit
import WebKit

extension WebTab {
    /// Takes over the results page loaded while the user was typing.
    ///
    /// Most searches start from a tab already showing a page. That page is
    /// kept behind the results rather than thrown away, so Back still reaches
    /// it — WebKit cannot move a back list from one view to another.
    /// - Returns: whether the page stood in for loading `url`.
    func adoptPrerendered(_ url: URL) -> Bool {
        guard let controller else { return false }
        let store = controller.contexts.store(for: snapshot.browsingContext)
        let options = PageContentOptions(controller.settings)
        guard let view = controller.warmer.prerenderer.take(url, store: store, options: options) else {
            return false
        }
        displaceLiveView(with: view)
        navigationEvents.started()
        mirrorState(of: view)
        // A page that already finished never tells its new delegate so, and
        // history and the favicon both hang off that call.
        if !view.isLoading { navigationDelegate?.webView(view, didFinish: nil) }
        return true
    }
}
