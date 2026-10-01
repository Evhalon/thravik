import AppKit
import WebKit

/// One row of the toolbar's extensions list, for the selected tab.
struct ExtensionToolbarItem: Identifiable {
    let id: UUID
    let name: String
    let icon: NSImage?
    let badge: String
    /// False for an extension that is off or failed to load: listed, but inert.
    let isRunning: Bool
    let hasAction: Bool
    let hasOptions: Bool
    /// Chrome-only features it needs that WebKit lacks; it may only half work.
    let unsupportedFeatures: [String]
}

/// The toolbar's extensions list, popups, and the pages extensions open.
extension ExtensionHost {
    /// Every installed extension, so the list matches Settings; only running
    /// ones answer a click.
    func toolbarItems(in tabs: TabController) -> [ExtensionToolbarItem] {
        _ = actionRevision
        let tab = selectedAdapter(in: tabs)
        return installed.map { record in
            let context = record.isEnabled ? contexts[record.id] : nil
            let action = context?.action(for: tab)
            return ExtensionToolbarItem(
                id: record.id,
                name: record.name,
                icon: action?.icon(for: CGSize(width: 18, height: 18))
                    ?? context?.webExtension.icon(for: CGSize(width: 18, height: 18)),
                badge: action?.badgeText ?? "",
                isRunning: context != nil,
                hasAction: action?.isEnabled ?? false,
                hasOptions: context?.webExtension.hasOptionsPage ?? false,
                unsupportedFeatures: unsupportedFeatures(for: record.id)
            )
        }
    }

    /// The button press itself is the user gesture `activeTab` waits for.
    func performAction(_ id: UUID, in tabs: TabController, anchor: NSView) {
        guard let context = contexts[id] else { return }
        popupAnchor = anchor
        context.performAction(for: selectedAdapter(in: tabs))
    }

    func presentPopup(of action: WKWebExtension.Action) {
        guard let popover = action.popupPopover else { return }
        popover.behavior = .transient
        if let anchor = popupAnchor, anchor.window != nil {
            popover.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .maxY)
        } else if let content = focusedWindow?.nativeWindow?.contentView {
            let corner = CGRect(x: content.bounds.maxX - 60, y: content.bounds.maxY - 44, width: 1, height: 1)
            popover.show(relativeTo: corner, of: content, preferredEdge: .maxY)
        }
    }

    public func openOptions(for id: UUID) {
        guard let context = contexts[id] else { return }
        openOptions(of: context)
    }

    func openOptions(of context: WKWebExtensionContext) {
        guard let url = context.optionsPageURL else { return }
        let window = focusedWindow
        _ = openTab(url, in: window, activate: true)
        window?.nativeWindow?.makeKeyAndOrderFront(nil)
    }

    func openTab(_ url: URL?, in window: ExtensionWindow?, activate: Bool) -> ExtensionTab? {
        guard let window, let tabs = window.tabs else { return nil }
        let previous = tabs.selectedID
        guard let opened = tabs.newTab(url: url) as? WebTab else { return nil }
        if !activate, let previous { tabs.select(previous) }
        return window.adapter(for: opened)
    }

    private func selectedAdapter(in tabs: TabController) -> ExtensionTab? {
        guard let window = window(for: tabs),
              let selected = tabs.webTabs.first(where: { $0.id == tabs.selectedID }) else { return nil }
        return window.adapter(for: selected)
    }
}
