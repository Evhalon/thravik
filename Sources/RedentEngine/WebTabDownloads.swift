import RedentKit
import WebKit

/// The three places WebKit can decide a navigation is a file rather than a
/// page. All of them end in the same coordinator.
extension WebTabNavigationDelegate {
    /// A response the web view cannot render is a download — that is what makes
    /// a link to a `.zip` or a `.dmg` save instead of doing nothing at all.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        navigationResponse.canShowMIMEType ? .allow : .download
    }

    /// Explicitly `@objc`: Swift does not infer it for these two optional
    /// requirements implemented in an extension, and WebKit would then simply
    /// never call them — a download that compiles and never starts.
    @objc
    func webView(
        _ webView: WKWebView,
        navigationAction: WKNavigationAction,
        didBecomeDownload download: WKDownload
    ) {
        adopt(download, from: navigationAction.request.url)
    }

    @objc
    func webView(
        _ webView: WKWebView,
        navigationResponse: WKNavigationResponse,
        didBecomeDownload download: WKDownload
    ) {
        adopt(download, from: navigationResponse.response.url)
    }

    private func adopt(_ download: WKDownload, from url: URL?) {
        guard let coordinator = tab?.controller?.downloads else { return }
        coordinator.adopt(download, from: url)
    }
}
