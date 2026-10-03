import Testing
@testable import RedentUI

struct SpaceScrollPositionTests {
    @Test func scrollingUpdatesPageAndProgress() {
        let start = SpaceScrollPosition(offset: 0, contentWidth: 900, viewportWidth: 180)
        let middle = SpaceScrollPosition(offset: 360, contentWidth: 900, viewportWidth: 180)
        let end = SpaceScrollPosition(offset: 720, contentWidth: 900, viewportWidth: 180)
        #expect(start.page == 1)
        #expect(middle.page == 3)
        #expect(end.page == 5)
        #expect(start.pageCount == 5)
        #expect(middle.progress == 0.5)
        #expect(end.progress == 1)
    }

    @Test func bounceRemainsWithinFirstAndLastPage() {
        let start = SpaceScrollPosition(offset: -30, contentWidth: 850, viewportWidth: 180)
        let end = SpaceScrollPosition(offset: 900, contentWidth: 850, viewportWidth: 180)
        #expect(start.page == 1)
        #expect(start.progress == 0)
        #expect(end.page == end.pageCount)
        #expect(end.progress == 1)
    }

    @Test func resizeRemovesPagination() {
        let position = SpaceScrollPosition(offset: 50, contentWidth: 180, viewportWidth: 200)
        #expect(!position.hasOverflow)
        #expect(position.page == 1)
        #expect(SpaceScrollPosition().pageCount == 1)
    }
}
