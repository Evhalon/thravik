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

    public var selectedTabVolume: Double { selectedTab?.volume ?? 1 }

    public func setSelectedTabVolume(_ level: Double) {
        selectedTab?.setVolume(level)
    }

    /// Always there over a page, so the control is where you look before the
    /// sound starts; it lights up once the tab actually plays something.
    public var showsVolumeControl: Bool { hasPage }

    public var isSelectedTabPlayingAudio: Bool { selectedTab?.isPlayingAudio ?? false }
}
