import Foundation
import Testing
@testable import RedentKit

@Suite("Horizontal swipe paging")
struct HorizontalSwipeTests {
    @Test("A left swipe past the threshold pages forward once")
    func leftSwipePagesNext() {
        var swipe = HorizontalSwipeAccumulator(threshold: 80)
        #expect(swipe.add(deltaX: -40, deltaY: 2) == nil)
        #expect(swipe.add(deltaX: -50, deltaY: 0) == 1)
        #expect(swipe.add(deltaX: -80, deltaY: 0) == nil)
    }

    @Test("A right swipe pages backward")
    func rightSwipePagesPrevious() {
        var swipe = HorizontalSwipeAccumulator(threshold: 80)
        #expect(swipe.add(deltaX: 80, deltaY: 10) == -1)
    }

    @Test("Vertical motion is ignored so the tab list can still scroll")
    func verticalIsIgnored() {
        var swipe = HorizontalSwipeAccumulator(threshold: 80)
        #expect(swipe.add(deltaX: -10, deltaY: -90) == nil)
        #expect(swipe.add(deltaX: -80, deltaY: -90) == nil)
    }

    @Test("Ending the gesture unlocks the next page turn")
    func endUnlocks() {
        var swipe = HorizontalSwipeAccumulator(threshold: 40)
        #expect(swipe.add(deltaX: -40, deltaY: 0) == 1)
        swipe.endGesture()
        #expect(swipe.add(deltaX: -40, deltaY: 0) == 1)
    }
}
