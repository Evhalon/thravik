import RedentKit
import WebKit

/// The three places WebKit can decide a navigation is a file rather than a
/// page. All of them end in the same coordinator.
extension WebTabNavigationDelegate {
    /// A response the web view cannot render, or one the server marked as an
    /// attachment, is a download — that is what makes a link to a `.zip` or an
    /// exported PDF save instead of doing nothing at all.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        let disposition = (navigationResponse.response as? HTTPURLResponse)?
            .value(forHTTPHeaderField: "Content-Disposition")
        let saves = DownloadPolicy.shouldDownload(
            canShowMIMEType: navigationResponse.canShowMIMEType,
            contentDisposition: disposition
        )
        return saves ? .download : .allow
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
        guard let tab, let controller = tab.controller,
              let coordinator = controller.downloads else { return }
        coordinator.adopt(download, from: url)
        closeIfEmptyPopup(tab, controller: controller)
    }

    /// A `target="_blank"` link to a file opens a popup that never shows a
    /// page; left alone it is a blank tab the user has to close by hand. The
    /// fetch belongs to the coordinator, so closing the view does not stop it.
    private func closeIfEmptyPopup(_ tab: WebTab, controller: TabController) {
        guard tab.snapshot.parentTabID != nil,
              tab.webView?.backForwardList.currentItem == nil else { return }
        let id = tab.id
        // After WebKit's callback returns, never from inside it.
        Task { controller.closePopup(id) }
    }
}
