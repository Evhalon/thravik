import RedentKit
import WebKit

extension TabController {
    /// Starts loading the page return would open for a search, in the store a
    /// new tab in this Space browses in. `nil` drops it: nothing typed any more
    /// could use it.
    public func prerender(_ url: URL?) {
        guard let url else { return warmer.prerenderer.discard() }
        // A private window's searches must not run through the persistent profile.
        guard privateSessionID == nil else { return }
        let context = spaceContext
        // Before the saved sign-ins are back the page would load signed out.
        guard contexts.cookieRestoration(for: context) == nil else { return }
        let store = contexts.store(for: context)
        let options = PageContentOptions(settings)
        guard !warmer.prerenderer.isPrerendering(url, store: store, options: options) else { return }
        let view = warmer.take(store: store, options: options)
            ?? WebViewFactory.makeWebView(configuration: WebViewFactory.makeConfiguration(
                store: store, options: options, contentBlocker: contentBlocker
            ))
        warmer.prerenderer.prerender(url, in: view, store: store, options: options)
        warmer.prepare(store: store, options: options, contentBlocker: contentBlocker)
    }

    /// Where a tab opened in the selected Space browses.
    var spaceContext: BrowsingContext {
        .container(
            workspace.spaces.first { $0.id == workspace.selectedSpaceID }?.containerID
                ?? BrowserContainer.defaultID
        )
    }
}
