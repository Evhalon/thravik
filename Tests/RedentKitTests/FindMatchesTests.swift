import RedentKit
import Testing

@Suite("Find match counts")
struct FindMatchesTests {
    @Test("Nothing found reads as 0/0, whatever position came back")
    func emptyStaysEmpty() {
        #expect(FindMatches(total: 0, current: 3) == .empty)
        #expect(FindMatches.empty.current == 0)
        #expect(FindMatches.empty.isEmpty)
    }

    @Test("A position outside the page's matches is pulled back inside it")
    func clampsPositionToTotal() {
        #expect(FindMatches(total: 12, current: 99).current == 12)
        #expect(FindMatches(total: 12, current: 0).current == 1)
        #expect(FindMatches(total: 12, current: 3).current == 3)
    }

    @Test("A negative count is no count at all")
    func rejectsNegativeTotals() {
        #expect(FindMatches(total: -4, current: 1).isEmpty)
    }
}
