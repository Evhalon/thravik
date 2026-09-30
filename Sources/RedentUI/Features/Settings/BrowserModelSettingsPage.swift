import Foundation
import RedentKit

/// Settings are a page in the window, not a sheet over it: they take the
/// page's place, and leave as soon as the user heads back to a tab.
extension BrowserModel {
    public func showSettings() {
        dismissPresentations()
        showsSettings = true
    }

    public func closeSettings() {
        showsSettings = false
    }

    /// A tab click always leads back to that tab's page — including the tab
    /// already selected, whose selection alone would change nothing.
    public func selectTab(_ id: UUID) {
        closeSettings()
        tabs.select(id)
    }

    func show(_ screen: BrowserScreen) {
        guard let route = SheetRoute(screen) else { return showSettings() }
        sheet = route
    }
}
