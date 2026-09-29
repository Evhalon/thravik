import RedentKit
import Testing
@testable import RedentUI

@MainActor
struct FloatingVideoModelTests {
    @Test("The overlay follows playback and routes controls to its source")
    func routesControls() {
        let player = VideoPlayerSpy()
        let model = FloatingVideoModel(player: player)
        #expect(!model.isPlaying)
        player.isVideoPlaying = true
        #expect(model.isPlaying)
        model.returnToTab()
        model.close()
        #expect(player.returnCount == 1)
        #expect(player.closeCount == 1)
    }

    @Test("The overlay never keeps a closed tab alive")
    func weakPlayerOwnership() {
        var player: VideoPlayerSpy? = VideoPlayerSpy()
        weak var weakPlayer = player
        let model = FloatingVideoModel(player: player ?? VideoPlayerSpy())
        player = nil
        #expect(weakPlayer == nil)
        #expect(!model.isPlaying)
        model.close()
        model.returnToTab()
    }

    @Test("Timeline and volume controls clamp values and follow the source state")
    func routesPlaybackControls() async {
        let player = VideoPlayerSpy()
        player.videoPlayback.seekStart = 10
        player.videoPlayback.seekEnd = 90
        player.videoPlayback.elapsed = 40
        let model = FloatingVideoModel(player: player)
        #expect(model.playback.elapsed == 40)
        model.seek(120)
        model.setVolume(2)
        for _ in 0..<30 {
            if player.seekTime != nil && player.volumeRequest != nil { break }
            await Task.yield()
        }
        #expect(player.seekTime == 90)
        #expect(player.volumeRequest == 1)
        player.videoPlayback.elapsed = 70
        player.videoPlayback.isMuted = true
        #expect(model.playback.elapsed == 70)
        model.toggleMute()
        for _ in 0..<30 {
            if player.muteCount > 0 { break }
            await Task.yield()
        }
        #expect(player.muteCount == 1)
        model.seek(.nan)
        model.setVolume(.infinity)
        await Task.yield()
        #expect(player.seekTime == 90)
        #expect(player.volumeRequest == 1)
    }
}

@MainActor
private final class VideoPlayerSpy: FloatingVideoControlling {
    var isVideoPlaying = false
    var returnCount = 0
    var closeCount = 0
    var videoPlayback = FloatingVideoPlayback()
    var seekTime: Double?
    var volumeRequest: Double?
    var muteCount = 0
    func returnVideoToTab() { returnCount += 1 }
    func closeFloatingVideo() { closeCount += 1 }
    func seekVideo(to seconds: Double) async { seekTime = seconds }
    func setVideoVolume(_ level: Double) async { volumeRequest = level }
    func toggleVideoMute() async { muteCount += 1 }
}
