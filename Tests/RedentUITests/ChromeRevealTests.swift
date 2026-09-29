import Testing
@testable import RedentUI

@MainActor @Suite("Edge-revealed chrome")
struct ChromeRevealTests {
    @Test("Clean mode fills the window only while its sidebar is collapsed")
    func fullPageVisibility() {
        let model = makeTestBrowserModel()
        #expect(!model.usesEdgeReveal)
        model.settings.setNavigationBarHidden(true)
        #expect(!model.usesEdgeReveal)
        model.toggleSidebar()
        #expect(model.usesEdgeReveal)
        model.toggleSidebar()
        #expect(!model.usesEdgeReveal)
        model.toggleSidebar()
        model.settings.tabLayout = .top
        #expect(!model.usesEdgeReveal)
        model.settings.tabLayout = .sidebar
        model.toggleFocusMode()
        #expect(!model.usesEdgeReveal)
    }

    @Test("Crossing from the edge into its panel cancels dismissal")
    func panelHandoff() async {
        let reveal = ChromeRevealModel()
        reveal.hover(.leftEdge, isInside: true)
        #expect(reveal.surface == .sidebar)
        reveal.hover(.leftEdge, isInside: false)
        let dismissal = reveal.dismissalTask
        reveal.hover(.sidebar, isInside: true)
        await dismissal?.value
        #expect(reveal.surface == .sidebar)
        reveal.hover(.sidebar, isInside: false)
        await reveal.dismissalTask?.value
        #expect(reveal.surface == nil)
    }

    @Test("Only one surface is revealed, and leaving an old edge cannot hide the new panel")
    func switchEdges() async {
        let reveal = ChromeRevealModel()
        reveal.hover(.leftEdge, isInside: true)
        reveal.hover(.topEdge, isInside: true)
        reveal.hover(.leftEdge, isInside: false)
        #expect(reveal.surface == .navigation)
        reveal.hover(.navigation, isInside: true)
        reveal.hover(.topEdge, isInside: false)
        #expect(reveal.surface == .navigation)
        reveal.hover(.navigation, isInside: false)
        await reveal.dismissalTask?.value
        #expect(reveal.surface == nil)
    }

    @Test("Editing or a presentation holds the panel and prevents switching surfaces")
    func interactionLock() async {
        let reveal = ChromeRevealModel()
        reveal.hover(.topEdge, isInside: true)
        reveal.setLocked(true)
        reveal.hover(.topEdge, isInside: false)
        reveal.hover(.leftEdge, isInside: true)
        #expect(reveal.surface == .navigation)
        reveal.hover(.leftEdge, isInside: false)
        reveal.setLocked(false)
        await reveal.dismissalTask?.value
        #expect(reveal.surface == nil)
    }

    @Test("Leaving clean mode cancels pending reveals and clears hover state")
    func resetCancelsDismissal() async {
        let reveal = ChromeRevealModel()
        reveal.hover(.leftEdge, isInside: true)
        reveal.hover(.leftEdge, isInside: false)
        let dismissal = reveal.dismissalTask
        reveal.reset()
        await dismissal?.value
        #expect(reveal.surface == nil)
        reveal.hover(.topEdge, isInside: true)
        #expect(reveal.surface == .navigation)
    }
}
