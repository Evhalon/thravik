import AppKit
import Foundation
import Testing
@testable import RedentEngine

@Suite("Floating video pop-out and return", .serialized)
@MainActor
struct FloatingVideoTransitionTests {
    @Test("The captured page position follows its browser window")
    func sourceFollowsWindow() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        let raw = try #require(try await fixture.value("""
        (() => { const r = document.querySelector('video').getBoundingClientRect();
            return {x:r.x,y:r.y,width:r.width,height:r.height,viewportWidth:innerWidth}; })()
        """) as? [String: Any])
        let source = try #require(FloatingVideoSource(bounds: raw, view: fixture.view))
        let original = source.frame
        fixture.window.setFrameOrigin(CGPoint(x: fixture.window.frame.minX + 50, y: fixture.window.frame.minY + 30))
        #expect(source.frame.minX - original.minX == 50)
        #expect(source.frame.minY - original.minY == 30)
        #expect(source.frame.size == original.size)
    }

    @Test("Pop-out geometry is bounded by the page viewport")
    func sourceClipsToViewport() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        let source = try #require(FloatingVideoSource(bounds: ["x": -1_000.0, "y": -1_000.0,
            "width": 1_000_000.0, "height": 1_000_000.0, "viewportWidth": Double(fixture.view.bounds.width)],
            view: fixture.view))
        #expect(source.frame.size == fixture.view.bounds.size)
        #expect(FloatingVideoSource(bounds: ["x": 10_000.0, "y": 10_000.0,
            "width": 100.0, "height": 100.0, "viewportWidth": Double(fixture.view.bounds.width)],
            view: fixture.view) == nil)
    }

    @Test("Closing a tab during pop-out cancels the animation and suspends the player")
    func closeDuringEntrance() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        let opening = Task { await fixture.tab.toggleFloatingVideo() }
        #expect(await fixture.settles { fixture.tab.isVideoFloating })
        let panel = try #require(fixture.tab.floatingVideoPanel)
        fixture.browser.close(fixture.tab.id)
        #expect(await opening.value == false)
        #expect(!panel.isVisible)
        #expect(!fixture.tab.isVideoFloating)
        #expect(await fixture.view.requestMediaPlaybackState() == .suspended)
    }

    @Test("Return retains the live player until the animation finishes and then restores its host")
    func animatedReturnRestoresHost() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        #expect(await fixture.tab.toggleFloatingVideo())
        let panel = try #require(fixture.tab.floatingVideoPanel)
        fixture.tab.returnVideoToTab()
        #expect(panel.isReturning)
        #expect(fixture.tab.isVideoFloating)
        fixture.tab.returnVideoToTab()
        #expect(await fixture.settles { !fixture.tab.isVideoFloating })
        #expect(!panel.isVisible)
        #expect(fixture.view.window === fixture.window)
        #expect(await fixture.view.requestMediaPlaybackState() == .playing)
    }

    @Test("Closing during return cannot reattach or revive the closed tab")
    func closeDuringReturn() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        #expect(await fixture.tab.toggleFloatingVideo())
        let panel = try #require(fixture.tab.floatingVideoPanel)
        fixture.tab.returnVideoToTab()
        fixture.browser.close(fixture.tab.id)
        #expect(await fixture.settles { !panel.isVisible })
        #expect(!fixture.tab.isVideoFloating)
        #expect(fixture.tab.floatingVideoPanel == nil)
        #expect(await fixture.view.requestMediaPlaybackState() == .suspended)
    }
}
