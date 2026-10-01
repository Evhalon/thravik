import AppKit
import WebKit

/// One tab as extensions see it (`chrome.tabs`).
///
/// Answers from the tab's snapshot while it hibernates, so a sleeping tab
/// keeps its place in the list; only scripting it needs the page awake.
@MainActor
final class ExtensionTab: NSObject, WKWebExtensionTab {
    private weak var tab: WebTab?
    private weak var window: ExtensionWindow?

    init(tab: WebTab, window: ExtensionWindow) {
        self.tab = tab
        self.window = window
    }

    func window(for context: WKWebExtensionContext) -> (any WKWebExtensionWindow)? { window }

    func indexInWindow(for context: WKWebExtensionContext) -> Int {
        guard let tab, let tabs = window?.tabs else { return NSNotFound }
        return tabs.webTabs.firstIndex { $0 === tab } ?? NSNotFound
    }

    func webView(for context: WKWebExtensionContext) -> WKWebView? { tab?.webView }
    func title(for context: WKWebExtensionContext) -> String? { tab?.title }
    func url(for context: WKWebExtensionContext) -> URL? { tab?.url }
    func isPinned(for context: WKWebExtensionContext) -> Bool { tab?.isPinned ?? false }
    func isPlayingAudio(for context: WKWebExtensionContext) -> Bool { tab?.isPlayingAudio ?? false }
    func isMuted(for context: WKWebExtensionContext) -> Bool { tab?.isMuted ?? false }
    func isLoadingComplete(for context: WKWebExtensionContext) -> Bool { !(tab?.isLoading ?? false) }
    func isReaderModeActive(for context: WKWebExtensionContext) -> Bool { tab?.isReaderActive ?? false }
    func zoomFactor(for context: WKWebExtensionContext) -> Double { tab?.zoom ?? 1 }

    func isSelected(for context: WKWebExtensionContext) -> Bool {
        guard let tab else { return false }
        return window?.tabs?.selectedID == tab.id
    }

    func size(for context: WKWebExtensionContext) -> CGSize {
        tab?.webView?.bounds.size ?? .zero
    }

    /// `activeTab` grants follow a click on the extension's own button.
    func shouldGrantPermissionsOnUserGesture(for context: WKWebExtensionContext) -> Bool { true }

    func loadURL(_ url: URL, for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        tab?.load(url)
        completionHandler(nil)
    }

    func reload(fromOrigin: Bool, for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        tab?.reload()
        completionHandler(nil)
    }

    func goBack(for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        tab?.goBack()
        completionHandler(nil)
    }

    func goForward(for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        tab?.goForward()
        completionHandler(nil)
    }

    func setZoomFactor(_ zoomFactor: Double, for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        tab?.setZoom(zoomFactor)
        completionHandler(nil)
    }

    func activate(for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        guard let tab, let tabs = window?.tabs else { return completionHandler(nil) }
        tabs.select(tab.id)
        window?.nativeWindow?.makeKeyAndOrderFront(nil)
        completionHandler(nil)
    }

    func close(for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        if let tab { window?.tabs?.close(tab.id) }
        completionHandler(nil)
    }
}
