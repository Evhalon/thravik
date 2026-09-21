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

    /// The toolbar's volume control appears once the tab has sound to control,
    /// and stays while the user has turned it down, so it can be turned back up.
    public var showsVolumeControl: Bool {
        guard let tab = selectedTab else { return false }
        return tab.isPlayingAudio || tab.isMuted || tab.volume < 1
    }
}
