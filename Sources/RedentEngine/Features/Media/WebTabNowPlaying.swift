import RedentKit
import WebKit

extension WebTab {
    /// Audible playback only: a muted autoplay clip is not something to control.
    /// A paused tab stays listed until the user has seen or dismissed it.
    public var nowPlaying: NowPlaying? {
        guard let lastMediaActivityAt else { return nil }
        return NowPlaying(
            tabID: id,
            title: mediaSessionTitle ?? title,
            artist: mediaSessionArtist,
            artworkURL: mediaSessionArtworkURL,
            isPlaying: isPlayingAudio,
            updatedAt: lastMediaActivityAt
        )
    }

    public func toggleMediaPlayback() async {
        guard let webView else { return }
        _ = try? await webView.callAsyncJavaScript(
            "return window.redentNowPlaying?.toggle()",
            in: nil,
            contentWorld: PageScripts.contentWorld
        )
    }

    public func dismissNowPlaying() {
        lastMediaActivityAt = nil
        webView?.evaluateJavaScript(
            "window.redentNowPlaying?.pause()", in: nil, in: PageScripts.contentWorld
        ) { _ in }
    }

    func receiveMediaSession(_ body: [String: Any]) {
        let parsed = MediaSessionMetadataParsing.parse(
            MediaSessionPayload(
                title: body["title"] as? String,
                artist: body["artist"] as? String,
                artwork: body["artwork"] as? String
            )
        )
        mediaSessionTitle = parsed.title
        mediaSessionArtist = parsed.artist
        mediaSessionArtworkURL = parsed.artworkURL
        if body["ended"] as? Bool == true { lastMediaActivityAt = nil }
    }

    func markMediaActivity(at date: Date = .now) {
        lastMediaActivityAt = date
    }

    /// The user is looking at the tab, or just left it idle: a paused player
    /// there no longer needs the sidebar card.
    func acknowledgeMedia() {
        guard !isPlayingAudio else { return }
        lastMediaActivityAt = nil
    }

    func clearMediaSession() {
        mediaSessionTitle = nil
        mediaSessionArtist = nil
        mediaSessionArtworkURL = nil
        lastMediaActivityAt = nil
    }
}
