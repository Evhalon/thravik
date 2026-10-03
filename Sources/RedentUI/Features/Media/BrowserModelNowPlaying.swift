import RedentKit

extension BrowserModel {
    public var sidebarNowPlaying: NowPlaying? {
        NowPlayingSelection.pick(
            from: tabs.tabs.compactMap(\.nowPlaying),
            selectedTabID: tabs.selectedID
        )
    }

    public var nowPlayingTab: (any BrowserTab)? {
        guard let id = sidebarNowPlaying?.tabID else { return nil }
        return tabs.tabs.first { $0.id == id }
    }

    public func focusNowPlayingTab() {
        guard let id = sidebarNowPlaying?.tabID else { return }
        tabs.select(id)
    }

    public func toggleNowPlayingPlayback() {
        guard let tab = nowPlayingTab else { return }
        Task { await tab.toggleMediaPlayback() }
    }

    public func toggleNowPlayingMute() {
        guard let tab = nowPlayingTab else { return }
        tab.setMuted(!tab.isMuted)
    }

    public func dismissNowPlaying() {
        nowPlayingTab?.dismissNowPlaying()
    }
}
