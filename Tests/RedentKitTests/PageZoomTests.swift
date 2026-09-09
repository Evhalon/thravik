import RedentKit
import Testing

@Suite("Page zoom")
struct PageZoomTests {
    @Test("Stepping up walks the ladder and stops at the top")
    func stepUpWalksTheLadder() {
        #expect(PageZoom.stepUp(from: 1) == 1.15)
        #expect(PageZoom.stepUp(from: 1.15) == 1.25)
        #expect(PageZoom.stepUp(from: PageZoom.maximum) == PageZoom.maximum)
    }

    @Test("Stepping down walks the ladder and stops at the bottom")
    func stepDownWalksTheLadder() {
        #expect(PageZoom.stepDown(from: 1) == 0.85)
        #expect(PageZoom.stepDown(from: 0.75) == 0.5)
        #expect(PageZoom.stepDown(from: PageZoom.minimum) == PageZoom.minimum)
    }

    @Test("A level between rungs snaps onto the ladder")
    func offLadderLevelsSnap() {
        #expect(PageZoom.stepUp(from: 1.2) == 1.25)
        #expect(PageZoom.stepDown(from: 1.2) == 1.15)
    }

    @Test("Levels from outside are clamped, and nonsense reads as 100%")
    func clampingKeepsLevelsUsable() {
        #expect(PageZoom.clamped(12) == PageZoom.maximum)
        #expect(PageZoom.clamped(0.01) == PageZoom.minimum)
        #expect(PageZoom.clamped(.nan) == PageZoom.identity)
    }

    @Test("Rounding survives a JSON round trip")
    func identityToleratesRoundTrip() {
        #expect(PageZoom.isIdentity(0.9999999))
        #expect(!PageZoom.isIdentity(1.15))
        #expect(PageZoom.label(1.25) == "125%")
    }
}
