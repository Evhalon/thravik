import Foundation
import Testing
@testable import RedentKit

@Suite("Bookmarks bar overflow")
struct BookmarksBarOverflowTests {
    @Test("Every chip stays on the bar when the row is wide enough")
    func fitsWithoutOverflow() {
        let plan = BookmarksBarOverflow.plan(
            itemWidths: [40, 50, 60],
            availableWidth: 200,
            overflowWidth: 28,
            spacing: 6
        )
        #expect(plan.visibleCount == 3)
        #expect(!plan.hasOverflow)
    }

    @Test("A short row reserves the overflow control and hides the rest")
    func overflowsWhenNarrow() {
        let plan = BookmarksBarOverflow.plan(
            itemWidths: [80, 80, 80],
            availableWidth: 160,
            overflowWidth: 28,
            spacing: 6
        )
        #expect(plan.visibleCount == 1)
        #expect(plan.overflowCount == 2)
        #expect(plan.hasOverflow)
    }

    @Test("An empty row has no overflow control")
    func emptyRow() {
        let plan = BookmarksBarOverflow.plan(
            itemWidths: [],
            availableWidth: 400,
            overflowWidth: 28,
            spacing: 6
        )
        #expect(plan.visibleCount == 0)
        #expect(!plan.hasOverflow)
    }

    @Test("A chip wider than the budget still lands in the overflow menu")
    func oversizedChipGoesToOverflow() {
        let plan = BookmarksBarOverflow.plan(
            itemWidths: [400],
            availableWidth: 100,
            overflowWidth: 28,
            spacing: 6
        )
        #expect(plan.visibleCount == 0)
        #expect(plan.overflowCount == 1)
    }

    @Test("Visible chips plus the overflow control never exceed the row")
    func overflowNeverExceedsRow() {
        let widths: [Double] = [90, 120, 45, 173, 60]
        let available = 300.0
        let plan = BookmarksBarOverflow.plan(
            itemWidths: widths, availableWidth: available, overflowWidth: 36, spacing: 6
        )
        let used = widths.prefix(plan.visibleCount).reduce(0, +) + Double(plan.visibleCount) * 6 + 36
        #expect(plan.hasOverflow)
        #expect(used <= available)
    }
}
