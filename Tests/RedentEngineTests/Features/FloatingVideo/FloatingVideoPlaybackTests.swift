import Foundation
import Testing
@testable import RedentEngine

@Suite("Floating video timeline and volume", .serialized)
@MainActor
struct FloatingVideoPlaybackTests {
    @Test("Seeking and volume affect the original video and update the native controls")
    func controlsOriginalVideo() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        #expect(await fixture.tab.toggleFloatingVideo())
        await fixture.tab.toggleVideoPlayback()
        #expect(await fixture.settles { !fixture.tab.isVideoPlaying && fixture.tab.videoPlayback.canSeek })
        let seconds = fixture.tab.videoPlayback.seekEnd / 2
        await fixture.tab.seekVideo(to: seconds)
        #expect(await fixture.settles { abs(fixture.tab.videoPlayback.elapsed - seconds) < 0.05 })
        #expect(abs((try await fixture.value("document.querySelector('video').currentTime") as? Double ?? -1) - seconds) < 0.05)
        await fixture.tab.setVideoVolume(0.35)
        #expect(await fixture.settles { abs(fixture.tab.videoPlayback.volume - 0.35) < 0.001 && !fixture.tab.videoPlayback.isMuted })
        #expect(try await fixture.value("document.querySelector('video').volume") as? Double == 0.35)
        await fixture.tab.toggleVideoMute()
        #expect(await fixture.settles { fixture.tab.videoPlayback.isMuted })
        await fixture.tab.toggleVideoMute()
        #expect(await fixture.settles { !fixture.tab.videoPlayback.isMuted })
    }

    @Test("The volume control can unmute a tab without the tab audio gate muting it again")
    func unmutesTab() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        #expect(await fixture.tab.toggleFloatingVideo())
        fixture.tab.setMuted(true)
        fixture.tab.setVolume(0.2)
        #expect(await fixture.settles { fixture.tab.videoPlayback.isMuted })
        await fixture.tab.setVideoVolume(0.6)
        #expect(await fixture.settles { fixture.tab.videoPlayback.volume == 0.6 && !fixture.tab.videoPlayback.isMuted })
        #expect(!fixture.tab.isMuted)
        #expect(fixture.tab.volume == 1)
    }

    @Test("Malformed playback events do not overwrite a valid state")
    func ignoresMalformedPlayback() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        let before = fixture.tab.videoPlayback
        fixture.tab.receiveVideoPlayback(["elapsed": Double.nan, "duration": -1])
        #expect(fixture.tab.videoPlayback == before)
    }
}
