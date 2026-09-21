import RedentKit
import WebKit

/// Reader: the page's article, rebuilt clean and laid over the page by the
/// isolated `redent` world. Nothing is fetched again and nothing leaves the tab.
extension WebTab {
    public func toggleReader() async {
        guard let webView else { return }
        let script = """
        typeof window.redentToggleReader === 'function' ? window.redentToggleReader() : false
        """
        // Bridged explicitly, like the autofill calls: the bare `try await`
        // resolves to the overload that does not wait for the result.
        let isOpen = await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(script, in: nil, in: PageScripts.contentWorld) { result in
                continuation.resume(returning: (try? result.get()) as? Bool ?? false)
            }
        }
        isReaderActive = isOpen
    }
}
