import Foundation
import Testing
@testable import RedentKit

@Suite("Split View layout")
struct SplitLayoutTests {
    @Test("An unsplit window has one pane and acts on the selection")
    func single() {
        let primary = UUID()
        let layout = SplitLayout()
        #expect(!layout.isSplit)
        #expect(layout.activeTabID(primary: primary) == primary)
        #expect(layout.visibleTabIDs(primary: primary) == [primary])
    }

    @Test("A tab cannot be split against itself")
    func noSelfSplit() {
        let primary = UUID()
        var layout = SplitLayout()
        layout.split(with: primary, primary: primary)
        #expect(!layout.isSplit)
    }

    @Test("Both panes count as on screen, so neither can be hibernated")
    func bothVisible() {
        let primary = UUID()
        let secondary = UUID()
        var layout = SplitLayout()
        layout.split(with: secondary, primary: primary)
        #expect(layout.visibleTabIDs(primary: primary) == [primary, secondary])
    }

    @Test("The chrome acts on the active pane, not on the window's selection")
    func activePaneOwnsTheChrome() {
        let primary = UUID()
        let secondary = UUID()
        var layout = SplitLayout()
        layout.split(with: secondary, primary: primary)
        #expect(layout.activeTabID(primary: primary) == secondary)

        layout.togglePane()
        #expect(layout.activeTabID(primary: primary) == primary)
    }

    @Test("With one pane there is nothing to switch to")
    func focusNeedsASecondPane() {
        var layout = SplitLayout()
        layout.focus(.secondary)
        #expect(layout.activePane == .primary)
    }

    @Test("A drag can never collapse a pane to nothing")
    func ratioIsClamped() {
        var layout = SplitLayout()
        layout.setRatio(0)
        #expect(layout.ratio == SplitLayout.minimumRatio)
        layout.setRatio(4)
        #expect(layout.ratio == SplitLayout.maximumRatio)
    }

    @Test("Closing the split keeps both tabs and returns the chrome to the selection")
    func closingKeepsTabs() {
        let primary = UUID()
        let secondary = UUID()
        var layout = SplitLayout()
        layout.split(with: secondary, primary: primary)
        layout.closeSecondary()
        #expect(!layout.isSplit)
        #expect(layout.activeTabID(primary: primary) == primary)
    }

    @Test("A pane whose tab was closed stops being a pane")
    func validation() {
        let primary = UUID()
        let secondary = UUID()
        var layout = SplitLayout()
        layout.split(with: secondary, primary: primary)
        layout.validate(against: [primary])
        #expect(!layout.isSplit)
        #expect(layout.activePane == .primary)
    }

    @Test("A pane whose tab is still open survives validation")
    func validationKeepsLiveTabs() {
        let primary = UUID()
        let secondary = UUID()
        var layout = SplitLayout()
        layout.split(with: secondary, primary: primary)
        layout.validate(against: [primary, secondary])
        #expect(layout.isSplit)
    }
}
