import RedentKit
import WebKit

extension WebTab {
    public func seekVideo(to seconds: Double) async {
        guard let seconds = videoPlayback.clampedTime(seconds), let webView else { return }
        _ = try? await webView.callAsyncJavaScript("return window.redentFloatVideo?.seek(seconds)",
            arguments: ["seconds": seconds], in: nil, contentWorld: PageScripts.contentWorld)
    }

    public func setVideoVolume(_ level: Double) async {
        guard level.isFinite, let webView else { return }
        setMuted(false)
        setVolume(1)
        _ = try? await webView.callAsyncJavaScript("return window.redentFloatVideo?.volume(level)",
            arguments: ["level": min(max(level, 0), 1)], in: nil, contentWorld: PageScripts.contentWorld)
    }

    public func toggleVideoMute() async {
        guard let webView else { return }
        let muted = !(videoPlayback.isMuted || isMuted)
        if !muted { setMuted(false) }
        _ = try? await webView.callAsyncJavaScript("return window.redentFloatVideo?.mute(muted)",
            arguments: ["muted": muted], in: nil, contentWorld: PageScripts.contentWorld)
    }

    func receiveVideoPlayback(_ state: [String: Any]) {
        guard let elapsed = state["elapsed"] as? Double, elapsed.isFinite, elapsed >= 0,
              let duration = state["duration"] as? Double, duration.isFinite, duration >= 0,
              let start = state["seekStart"] as? Double, start.isFinite, start >= 0,
              let end = state["seekEnd"] as? Double, end.isFinite, end >= start,
              let level = state["volume"] as? Double, level.isFinite,
              let muted = state["muted"] as? Bool, let live = state["live"] as? Bool else { return }
        var playback = FloatingVideoPlayback()
        playback.elapsed = elapsed
        playback.duration = duration
        playback.seekStart = start
        playback.seekEnd = end
        playback.volume = min(max(level, 0), 1)
        playback.isMuted = muted || isMuted
        playback.isLive = live
        videoPlayback = playback
    }
}
