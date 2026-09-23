import WebKit

/// Builds `WKWebViewConfiguration`s and `WKWebView`s consistently.
///
/// Every tab's configuration is a fresh instance (so each tab gets its own
/// `WKUserContentController` and can register its own message handler). The
/// data store is *not* per tab: `BrowsingContextRegistry` hands out one store
/// per browsing context, so sibling tabs in a Container share cookies and
/// session storage while other Containers cannot see them. `WKProcessPool` is
/// not used here: on this SDK it is a formally deprecated no-op — WebKit
/// shares web content processes on its own.
@MainActor
enum WebViewFactory {

    static func makeConfiguration(
        store: WKWebsiteDataStore, options: PageContentOptions, contentBlocker: ContentBlocker?
    ) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = store
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences.preferredContentMode = .desktop
        // Safari's autoplay gate is the modern equivalent of the old plugin
        // block: YouTube ads and quality switches start a new media element
        // without a click, and a blocked one takes the player down with it.
        config.mediaTypesRequiringUserActionForPlayback = []
        // WebKit ships element fullscreen off on macOS, which is why the
        // fullscreen button on a video site did nothing at all.
        config.preferences.isElementFullscreenEnabled = true
        // `isInspectable` permits Safari to attach, while this WebKit switch
        // also exposes Inspect Element in the page's contextual menu.
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        // A tab that is not on screen is detached from the window, and WebKit
        // will then stop running its JavaScript and layout altogether. Playing
        // media and in-flight loads are exempt, so a background video or a page
        // still loading keeps going.
        config.preferences.inactiveSchedulingPolicy = .suspend
        installContent(into: config, options: options, contentBlocker: contentBlocker)
        return config
    }

    /// The view for a window the page itself opened.
    ///
    /// WebKit hands back a configuration carrying the opener's own
    /// `WKUserContentController`, so the popup gets a fresh one: registering
    /// this tab's bridge on the shared object would tear the opener's handler
    /// out from under it, and hibernating either tab would unregister both.
    /// Everything else — the data store, the opener link — is kept as WebKit
    /// built it, which is what lets `window.opener` survive.
    static func makePopupView(
        configuration: WKWebViewConfiguration, options: PageContentOptions, contentBlocker: ContentBlocker?
    ) -> WKWebView {
        configuration.userContentController = WKUserContentController()
        installContent(into: configuration, options: options, contentBlocker: contentBlocker)
        return makeWebView(configuration: configuration)
    }

    static func makeWebView(configuration: WKWebViewConfiguration) -> WKWebView {
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.allowsBackForwardNavigationGestures = true
        view.isInspectable = true
        view.allowsMagnification = true
        view.customUserAgent = nil
        view.appearance = nil
        // A clear page in a non-opaque window makes hardware video composite
        // as a black rectangle the moment the player adds an overlay.
        view.underPageBackgroundColor = .windowBackgroundColor
        return view
    }

    /// Brings an already-live web view's rule lists and scripts in line with
    /// `options`. Remove first so a late compile cannot add the same list
    /// twice. Scripts take effect from the next page load.
    static func apply(_ options: PageContentOptions, contentBlocker: ContentBlocker?, on webView: WKWebView) {
        let controller = webView.configuration.userContentController
        controller.removeAllContentRuleLists()
        contentBlocker?.lists(for: options).forEach(controller.add)
        controller.removeAllUserScripts()
        PageScripts.install(into: controller, quiets: options.quietsPages)
    }

    private static func installContent(
        into config: WKWebViewConfiguration, options: PageContentOptions, contentBlocker: ContentBlocker?
    ) {
        // Without a name WebKit's agent stops at "(KHTML, like Gecko)", which
        // reads as an embedded web view to every site that checks.
        config.applicationNameForUserAgent = BrowserUserAgent.safariApplicationName
        PageScripts.install(into: config.userContentController, quiets: options.quietsPages)
        contentBlocker?.lists(for: options).forEach(config.userContentController.add)
    }
}
