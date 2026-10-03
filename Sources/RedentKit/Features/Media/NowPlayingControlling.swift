import Foundation

@MainActor
public protocol NowPlayingControlling: AnyObject {
    var nowPlaying: NowPlaying? { get }
    func toggleMediaPlayback() async
    /// Pauses the tab's media and drops it from the sidebar card.
    func dismissNowPlaying()
}

public extension NowPlayingControlling {
    var nowPlaying: NowPlaying? { nil }
    func toggleMediaPlayback() async {}
    func dismissNowPlaying() {}
}
