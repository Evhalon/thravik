import Foundation

/// Picks the sidebar mini-player tab, never the selected one. A background tab
/// that is still playing wins; otherwise the newest paused one stays, so the
/// card that paused it can resume it.
public enum NowPlayingSelection {
    public static func pick(from items: [NowPlaying], selectedTabID: UUID?) -> NowPlaying? {
        let background = items.filter { $0.tabID != selectedTabID }
        return newest(background.filter(\.isPlaying)) ?? newest(background)
    }

    private static func newest(_ items: [NowPlaying]) -> NowPlaying? {
        items.max { lhs, rhs in
            if lhs.updatedAt != rhs.updatedAt { return lhs.updatedAt < rhs.updatedAt }
            return lhs.tabID.uuidString < rhs.tabID.uuidString
        }
    }
}
