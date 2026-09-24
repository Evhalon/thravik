import Foundation
import Testing
@testable import RedentKit

@Suite("Space swipe")
struct SpaceSwipeTests {
    @Test("The page follows the fingers once the swipe is clearly sideways")
    func followsHorizontalMotion() {
        var swipe = SpaceSwipe()
        // Too little to tell a direction yet, but it still counts once decided.
        let start = swipe.add(deltaX: -2, deltaY: 0)
        let follow = swipe.add(deltaX: -30, deltaY: 1)
        #expect(!start && follow)
        #expect(swipe.travel == -32)
        #expect(swipe.offset(hasPrevious: true, hasNext: true) == -32)
    }

    @Test("A vertical start leaves the whole gesture to the tab list")
    func verticalStartIsNeverClaimed() {
        var swipe = SpaceSwipe()
        let start = swipe.add(deltaX: 0, deltaY: -5)
        let sideways = swipe.add(deltaX: -80, deltaY: 0)
        #expect(!start && !sideways)
        #expect(swipe.settle(pageWidth: 200, hasPrevious: true, hasNext: true) == 0)
    }

    @Test("Past a third of the page, letting go turns it; short of that it springs back")
    func settlesByDistance() {
        var far = SpaceSwipe()
        for _ in 0..<10 { _ = far.add(deltaX: -8, deltaY: 0) }
        #expect(far.settle(pageWidth: 200, hasPrevious: true, hasNext: true) == 1)

        var near = SpaceSwipe()
        for _ in 0..<4 { _ = near.add(deltaX: 8, deltaY: 0) }
        #expect(near.settle(pageWidth: 200, hasPrevious: true, hasNext: true) == 0)
    }

    @Test("A quick flick turns the page even when it travelled only a little")
    func flickTurnsThePage() {
        var swipe = SpaceSwipe()
        _ = swipe.add(deltaX: 4, deltaY: 0)
        _ = swipe.add(deltaX: 20, deltaY: 0)
        #expect(swipe.settle(pageWidth: 200, hasPrevious: true, hasNext: true) == -1)
    }

    @Test("Past the last Space the page resists and always springs back")
    func edgeResistsAndReturns() {
        var swipe = SpaceSwipe()
        for _ in 0..<20 { _ = swipe.add(deltaX: -10, deltaY: 0) }
        #expect(swipe.offset(hasPrevious: true, hasNext: false) == -50)
        #expect(swipe.settle(pageWidth: 200, hasPrevious: true, hasNext: false) == 0)
    }
}
