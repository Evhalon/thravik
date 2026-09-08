import RedentKit
import WebKit

/// Navigation + UI delegate for one tab's web view.
///
/// Holds `tab` weakly: the `WKWebView` retains its delegate strongly, and
/// `WebTab` retains this delegate strongly too. A strong reference back to
/// `tab` here would complete a retain cycle that keeps the tab — and its web
/// content process — alive forever, even past `hibernate()`.
@MainActor
final class WebTabNavigationDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
    private weak var tab: WebTab?

    init(tab: WebTab) {
        self.tab = tab
    }

    /// Resolved here rather than in the permission extension, which cannot see
    /// `tab` — and so cannot tell which Container the request came from.
    func permissionDecision(for origin: Origin, _ permission: SitePermission) -> PermissionDecision? {
        guard let tab, let decide = tab.controller?.permissionDecider else { return nil }
        let container = tab.snapshot.containerID ?? BrowserContainer.defaultID
        return decide(SiteKey(origin: origin, containerID: container), permission)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        let target = LinkActivation.target(
            isUserLink: navigationAction.navigationType == .linkActivated,
            commandHeld: navigationAction.modifierFlags.contains(.command),
            shiftHeld: navigationAction.modifierFlags.contains(.shift)
        )
        if target != .currentTab {
            if let url = navigationAction.request.url, let tab {
                tab.controller?.openCommandClickedLink(
                    url: url, from: tab.snapshot, selecting: target == .foregroundTab
                )
            }
            return .cancel
        }
        BrowserUserAgent.applyBeforeNavigation(navigationAction, on: webView)
        tab?.timelineRecorder.willNavigate(navigationAction.navigationType)
        return .allow
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        BrowserUserAgent.apply(to: webView, for: webView.url)
        webView.reload()
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        tab?.navigationEvents.started()
    }

    func webView(
        _ webView: WKWebView,
        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!
    ) {
        tab?.timelineRecorder.redirected()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        tab?.handleDidFinishNavigation(webView: webView)
        if let tab {
            tab.timelineRecorder.finished(tab, webView: webView)
            tab.snapshot.url = webView.url
            tab.snapshot.title = webView.title ?? tab.title
            tab.navigationEvents.finished(tab)
        }
    }

    /// Makes `target="_blank"` and `window.open` work: the popup opens as a
    /// Redent tab rather than a detached window, and WebKit gets the view it
    /// asked for so the popup keeps `window.opener`. A `window.open()` with no
    /// address is a tab too — OAuth flows open the blank window first and
    /// navigate it afterwards.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil,
              let tab, let controller = tab.controller else { return nil }
        let url = navigationAction.request.url
        guard !controller.shouldBlockPopup(url: url, from: tab.snapshot.url) else { return nil }
        return controller.openPopupTab(
            configuration: configuration, url: url, of: tab.snapshot
        ).webView
    }

    func webViewDidClose(_ webView: WKWebView) {
        guard let tab else { return }
        tab.controller?.closePopup(tab.id)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async {
        await JavaScriptPanelPresenter.alert(message: message, on: webView)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async -> Bool {
        await JavaScriptPanelPresenter.confirm(message: message, on: webView)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo
    ) async -> String? {
        await JavaScriptPanelPresenter.prompt(message: prompt, defaultText: defaultText, on: webView)
    }
}
