import Foundation
import Testing
@testable import RedentKit

@Suite("Space paging")
struct SpacePagingTests {
    @Test("Swipe paging loops past the ends")
    func pagingLoops() {
        let ids = [UUID(), UUID(), UUID()]
        #expect(SpacePaging.neighbor(of: ids[0], in: ids, step: -1) == ids[2])
        #expect(SpacePaging.neighbor(of: ids[0], in: ids, step: 1) == ids[1])
        #expect(SpacePaging.neighbor(of: ids[2], in: ids, step: 1) == ids[0])
        #expect(SpacePaging.neighbor(of: ids[0], in: [ids[0]], step: 1) == nil)
    }

    @Test("The last Space is drawn just left of the first, and a far one not at all")
    func pagerSidesLoop() {
        #expect(SpacePaging.sides(count: 4, lean: 1) == [-1, 0, 1])
        #expect(SpacePaging.sides(count: 2, lean: -1) == [0, -1])
        #expect(SpacePaging.sides(count: 2, lean: 1) == [0, 1])
        #expect(SpacePaging.sides(count: 1, lean: 1) == [0])
        #expect(SpacePaging.index(ofPage: -1, count: 4) == 3)
    }

    @Test("Turning past the last Space moves one page on, never back across the row")
    func nearestPageCrossesTheSeam() {
        #expect(SpacePaging.nearestPage(showing: 0, from: 2, count: 3, lean: 1) == 3)
        #expect(SpacePaging.nearestPage(showing: 2, from: 0, count: 3, lean: 1) == -1)
        #expect(SpacePaging.nearestPage(showing: 1, from: 4, count: 3, lean: 1) == 4)
        #expect(SpacePaging.nearestPage(showing: 1, from: 0, count: 2, lean: -1) == -1)
        #expect(SpacePaging.nearestPage(showing: 1, from: 0, count: 2, lean: 1) == 1)
    }
}
