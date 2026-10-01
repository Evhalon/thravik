import AppKit
import WebKit

/// One browser window as extensions see it (`chrome.windows`).
///
/// Weak to both the tab controller and the AppKit window: the window owns
/// its tabs, and an extension asking about a closed window must get nothing
/// rather than keep the window's web views alive.
@MainActor
final class ExtensionWindow: NSObject, WKWebExtensionWindow {
    private(set) weak var tabs: TabController?
    weak var nativeWindow: NSWindow?
    /// What extensions were last told, so only real changes are reported.
    var reportedTabIDs: [UUID] = []
    var reportedActiveID: UUID?
    private var tabAdapters: [UUID: ExtensionTab] = [:]

    init(tabs: TabController) {
        self.tabs = tabs
    }

    /// The same object every time for the same tab: WebKit tells tabs apart
    /// by identity.
    func adapter(for tab: WebTab) -> ExtensionTab {
        if let existing = tabAdapters[tab.id] { return existing }
        let created = ExtensionTab(tab: tab, window: self)
        tabAdapters[tab.id] = created
        return created
    }

    func forgetAdapter(_ id: UUID) -> ExtensionTab? {
        tabAdapters.removeValue(forKey: id)
    }

    var allAdapters: [ExtensionTab] {
        (tabs?.webTabs ?? []).map(adapter(for:))
    }

    func tabs(for context: WKWebExtensionContext) -> [any WKWebExtensionTab] {
        allAdapters
    }

    func activeTab(for context: WKWebExtensionContext) -> (any WKWebExtensionTab)? {
        guard let tabs, let selected = tabs.webTabs.first(where: { $0.id == tabs.selectedID }) else { return nil }
        return adapter(for: selected)
    }

    func windowType(for context: WKWebExtensionContext) -> WKWebExtension.WindowType { .normal }

    func windowState(for context: WKWebExtensionContext) -> WKWebExtension.WindowState {
        guard let nativeWindow else { return .normal }
        if nativeWindow.isMiniaturized { return .minimized }
        if nativeWindow.styleMask.contains(.fullScreen) { return .fullscreen }
        return nativeWindow.isZoomed ? .maximized : .normal
    }

    func isPrivate(for context: WKWebExtensionContext) -> Bool { false }

    func frame(for context: WKWebExtensionContext) -> CGRect {
        nativeWindow?.frame ?? .null
    }

    func screenFrame(for context: WKWebExtensionContext) -> CGRect {
        nativeWindow?.screen?.frame ?? .null
    }

    func focus(for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        NSApp.activate()
        nativeWindow?.makeKeyAndOrderFront(nil)
        completionHandler(nil)
    }

    func close(for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        nativeWindow?.performClose(nil)
        completionHandler(nil)
    }
}
