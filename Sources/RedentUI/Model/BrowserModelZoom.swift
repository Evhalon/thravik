import Foundation
import RedentKit

/// Page zoom for whichever tab the window is showing.
///
/// The level belongs to the tab, not to the window: switching tabs shows each
/// page at the size the user left it, and the menu simply reports the one in
/// front.
extension BrowserModel {
    public var zoomLevel: Double { selectedTab?.zoom ?? PageZoom.identity }

    public var zoomLabel: String { PageZoom.label(zoomLevel) }

    public var canZoomIn: Bool {
        guard let tab = selectedTab else { return false }
        return tab.zoom < PageZoom.maximum
    }

    public var canZoomOut: Bool {
        guard let tab = selectedTab else { return false }
        return tab.zoom > PageZoom.minimum
    }

    public var canResetZoom: Bool {
        guard let tab = selectedTab else { return false }
        return !PageZoom.isIdentity(tab.zoom)
    }

    public func zoomIn() {
        selectedTab?.setZoom(PageZoom.stepUp(from: zoomLevel))
    }

    public func zoomOut() {
        selectedTab?.setZoom(PageZoom.stepDown(from: zoomLevel))
    }

    public func resetZoom() {
        selectedTab?.setZoom(PageZoom.identity)
    }
}
