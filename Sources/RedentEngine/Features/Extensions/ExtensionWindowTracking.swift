import AppKit
import WebKit

/// Keeps WebKit's picture of windows and tabs in step with the browser's.
///
/// Rather than hook every tab mutation, each window's change notification
/// diffs the tab list against what extensions were last told — one pass per
/// change, and nothing can be missed by a code path that forgot to report.
extension ExtensionHost {
    public func attach(_ tabs: TabController) {
        guard !tabs.isPrivate, window(for: tabs) == nil else { return }
        let window = ExtensionWindow(tabs: tabs)
        windows.append(window)
        tabs.extensions = self
        tabs.warmer.extensionController = controller
        controller.didOpenWindow(window)
        tabsChanged(in: tabs)
    }

    public func detach(_ tabs: TabController) {
        guard let position = windows.firstIndex(where: { $0.tabs === tabs }) else { return }
        let window = windows.remove(at: position)
        for id in window.reportedTabIDs {
            if let adapter = window.forgetAdapter(id) { controller.didCloseTab(adapter, windowIsClosing: true) }
        }
        controller.didCloseWindow(window)
        tabs.extensions = nil
    }

    /// `chrome.windows` reports frames and focus from the AppKit window,
    /// which exists only once SwiftUI has put the scene on screen.
    public func windowBecameReady(_ tabs: TabController, nativeWindow: NSWindow) {
        window(for: tabs)?.nativeWindow = nativeWindow
    }

    func tabsChanged(in tabs: TabController) {
        guard let window = window(for: tabs) else { return }
        let current = tabs.webTabs.map(\.id)
        let currentSet = Set(current)
        let previousSet = Set(window.reportedTabIDs)
        for id in window.reportedTabIDs where !currentSet.contains(id) {
            if let adapter = window.forgetAdapter(id) { controller.didCloseTab(adapter, windowIsClosing: false) }
        }
        for tab in tabs.webTabs where !previousSet.contains(tab.id) {
            controller.didOpenTab(window.adapter(for: tab))
        }
        window.reportedTabIDs = current
        reportActivation(in: window, tabs: tabs)
    }

    /// A finished load is when a tab's address and title settle.
    func tabDidLoad(_ tab: WebTab) {
        guard let tabs = tab.controller, let window = window(for: tabs) else { return }
        controller.didChangeTabProperties([.URL, .title, .loading], for: window.adapter(for: tab))
    }

    var focusedWindow: ExtensionWindow? {
        windows.first { $0.nativeWindow?.isKeyWindow == true }
            ?? windows.first { $0.nativeWindow?.isMainWindow == true }
            ?? windows.first
    }

    func window(for tabs: TabController) -> ExtensionWindow? {
        windows.first { $0.tabs === tabs }
    }

    private func reportActivation(in window: ExtensionWindow, tabs: TabController) {
        guard tabs.selectedID != window.reportedActiveID else { return }
        let previous = window.reportedActiveID.flatMap { id in tabs.webTabs.first { $0.id == id } }
        window.reportedActiveID = tabs.selectedID
        guard let selected = tabs.webTabs.first(where: { $0.id == tabs.selectedID }) else { return }
        controller.didActivateTab(
            window.adapter(for: selected), previousActiveTab: previous.map(window.adapter(for:))
        )
    }
}
