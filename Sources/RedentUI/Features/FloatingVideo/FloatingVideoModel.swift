import Observation
import RedentKit

@MainActor
@Observable
public final class FloatingVideoModel {
    private weak var player: (any FloatingVideoControlling)?

    public init(player: any FloatingVideoControlling) { self.player = player }

    public var isPlaying: Bool { player?.isVideoPlaying ?? false }
    public var playback: FloatingVideoPlayback { player?.videoPlayback ?? FloatingVideoPlayback() }
    public func close() { player?.closeFloatingVideo() }
    public func returnToTab() { player?.returnVideoToTab() }
    public func togglePlayback() {
        Task { [weak player] in await player?.toggleVideoPlayback() }
    }
    public func seek(_ seconds: Double) {
        guard let seconds = playback.clampedTime(seconds) else { return }
        Task { [weak player] in await player?.seekVideo(to: seconds) }
    }
    public func setVolume(_ level: Double) {
        guard level.isFinite else { return }
        let volume = min(max(level, 0), 1)
        Task { [weak player] in await player?.setVideoVolume(volume) }
    }
    public func toggleMute() {
        Task { [weak player] in await player?.toggleVideoMute() }
    }
}
