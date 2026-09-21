import Foundation
import RedentKit

/// Reader and tab audio: the two ways to quiet a page down without leaving it.
extension BrowserModel {
    public var isReaderActive: Bool { selectedTab?.isReaderActive ?? false }

    public func toggleReader() {
        guard let tab = selectedTab, hasPage else { return }
        Task { await tab.toggleReader() }
    }

    public var isSelectedTabMuted: Bool { selectedTab?.isMuted ?? false }

    public func toggleMute() {
        guard let tab = selectedTab else { return }
        tab.setMuted(!tab.isMuted)
    }
}
