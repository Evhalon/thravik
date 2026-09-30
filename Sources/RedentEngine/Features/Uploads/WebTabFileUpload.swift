import WebKit

extension WebTabNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo
    ) async -> [URL]? {
        await FileUploadPanelPresenter.chooseFiles(parameters, on: webView)
    }
}
