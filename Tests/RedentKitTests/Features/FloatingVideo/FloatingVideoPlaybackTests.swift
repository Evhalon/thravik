import Foundation
import RedentKit
import Testing

struct FloatingVideoPlaybackTests {
    @Test("Seek control clamps both ordinary playback and a live DVR window")
    func seekRange() {
        var playback = FloatingVideoPlayback()
        #expect(!playback.canSeek)
        #expect(playback.clampedTime(50) == nil)
        playback.seekStart = 120
        playback.seekEnd = 180
        playback.isLive = true
        #expect(playback.canSeek)
        #expect(playback.clampedTime(20) == 120)
        #expect(playback.clampedTime(160) == 160)
        #expect(playback.clampedTime(200) == 180)
        #expect(playback.clampedTime(.nan) == nil)
        playback.seekEnd = .infinity
        #expect(!playback.canSeek)
    }

    @Test("Timestamps cover short and long videos without overflowing")
    func timestamps() {
        #expect(FloatingVideoPlayback.timestamp(0) == "0:00")
        #expect(FloatingVideoPlayback.timestamp(89.9) == "1:29")
        #expect(FloatingVideoPlayback.timestamp(3_661) == "1:01:01")
        #expect(FloatingVideoPlayback.timestamp(.nan) == "--:--")
        #expect(FloatingVideoPlayback.timestamp(.infinity) == "--:--")
        #expect(FloatingVideoPlayback.timestamp(Double(Int.max)) == "--:--")
    }
}
