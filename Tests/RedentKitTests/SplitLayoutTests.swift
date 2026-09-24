import Foundation
import Testing
@testable import RedentKit

@Suite("Split View layout")
struct SplitLayoutTests {
    @Test("An unsplit window shows only its selection")
    func single() {
        let primary = UUID()
        let layout = SplitLayout()
        #expect(!layout.isSplit)
        #expect(!layout.isShowing(primary: primary))
        #expect(layout.visibleTabIDs(primary: primary) == [primary])
    }

    @Test("A tab cannot be split against itself")
    func noSelfSplit() {
        let primary = UUID()
        var layout = SplitLayout()
        layout.split(with: primary, primary: primary)
        #expect(!layout.isSplit)
    }

    @Test("Every pane counts as on screen, so none can be hibernated")
    func allVisible() {
        let primary = UUID(), second = UUID(), third = UUID()
        var layout = SplitLayout()
        layout.split(with: second, primary: primary)
        layout.split(with: third, primary: primary)
        #expect(layout.tabIDs == [primary, second, third])
        #expect(layout.visibleTabIDs(primary: second) == [primary, second, third])
    }

    @Test("Selecting a tab outside the split sets it aside without ending it")
    func splitIsSetAside() {
        let primary = UUID(), second = UUID(), other = UUID()
        var layout = SplitLayout()
        layout.split(with: second, primary: primary)
        #expect(!layout.isShowing(primary: other))
        #expect(layout.visibleTabIDs(primary: other) == [other])
        #expect(layout.isShowing(primary: second))
    }

    @Test("Panes stop at the cap, and one tab never fills two")
    func capAndDuplicates() {
        let primary = UUID()
        var layout = SplitLayout()
        let extra = (0..<6).map { _ in UUID() }
        extra.forEach { layout.split(with: $0, primary: primary) }
        layout.split(with: extra[0], primary: primary)
        #expect(layout.paneCount == SplitLayout.maximumPanes)
        #expect(Set(layout.tabIDs).count == layout.tabIDs.count)
    }

    @Test("Splitting from a tab outside the split starts a new one")
    func newSplitReplacesOld() {
        let first = UUID(), second = UUID(), third = UUID(), fourth = UUID()
        var layout = SplitLayout()
        layout.split(with: second, primary: first)
        layout.split(with: fourth, primary: third)
        #expect(layout.tabIDs == [third, fourth])
    }

    @Test("Switching panes cycles through all of them")
    func cycling() {
        let primary = UUID(), second = UUID(), third = UUID()
        var layout = SplitLayout()
        layout.split(with: second, primary: primary)
        layout.split(with: third, primary: primary)
        #expect(layout.tabID(after: primary) == second)
        #expect(layout.tabID(after: third) == primary)
    }

    @Test("A drag moves one seam and can never collapse a pane")
    func resizeIsClamped() {
        let primary = UUID()
        var layout = SplitLayout()
        layout.split(with: UUID(), primary: primary)
        layout.split(with: UUID(), primary: primary)
        let start = layout.fractions
        layout.resize(divider: 0, from: start, by: -1)
        #expect(layout.fractions[0] == SplitLayout.minimumFraction)
        #expect(layout.fractions[2] == start[2])
        #expect(abs(layout.fractions.reduce(0, +) - 1) < 0.0001)
    }

    @Test("A split left with one tab is no split")
    func removingDownToOne() {
        let primary = UUID(), second = UUID()
        var layout = SplitLayout()
        layout.split(with: second, primary: primary)
        layout.remove(second)
        #expect(!layout.isSplit)
        #expect(layout.tabIDs.isEmpty)
    }

    @Test("A pane whose tab was closed stops being a pane")
    func validation() {
        let primary = UUID(), second = UUID(), third = UUID()
        var layout = SplitLayout()
        layout.split(with: second, primary: primary)
        layout.split(with: third, primary: primary)
        layout.validate(against: [primary, third])
        #expect(layout.tabIDs == [primary, third])
        #expect(layout.fractions.count == 2)
    }

    @Test("A layout round-trips through its own encoding")
    func roundTrip() throws {
        let primary = UUID()
        var layout = SplitLayout()
        layout.split(with: UUID(), primary: primary)
        layout.split(with: UUID(), primary: primary)
        let decoded = try JSONDecoder().decode(SplitLayout.self, from: JSONEncoder().encode(layout))
        #expect(decoded.tabIDs == layout.tabIDs)
        #expect(decoded.fractions.count == 3)
    }

    @Test("A layout saved by an earlier build restores as no split")
    func legacyDecoding() throws {
        let json = #"{"secondaryTabID":"\#(UUID().uuidString)","activePane":"secondary","ratio":0.3}"#
        let layout = try JSONDecoder().decode(SplitLayout.self, from: Data(json.utf8))
        #expect(!layout.isSplit)
    }
}
