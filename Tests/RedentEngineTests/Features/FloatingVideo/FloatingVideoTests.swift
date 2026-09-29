import AppKit
import Foundation
import Testing
import WebKit
@testable import RedentEngine

@Suite("Floating video", .serialized)
@MainActor
struct FloatingVideoTests {
    @Test("Floating and returning preserves the player and restores page styles")
    func roundTripPreservesPlayback() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        let style = try await fixture.value("document.querySelector('main').getAttribute('style')") as? String
        #expect(await fixture.tab.toggleFloatingVideo())
        let panel = try #require(fixture.tab.floatingVideoPanel)
        #expect(panel.level == .floating)
        #expect(panel.collectionBehavior.contains(.canJoinAllSpaces))
        #expect(fixture.view.window === panel)
        #expect(fixture.tab.webView === fixture.view)
        #expect(await fixture.view.requestMediaPlaybackState() == .playing)
        #expect(try await fixture.value("document.querySelector('video').parentElement.tagName") as? String == "MAIN")

        fixture.tab.returnVideoToTab()
        #expect(await fixture.settles { !fixture.tab.isVideoFloating })
        #expect(!fixture.tab.isVideoFloating)
        #expect(!panel.isVisible)
        #expect(fixture.view.window === fixture.window)
        #expect(try await fixture.value("document.querySelector('main').getAttribute('style')") as? String == style)
        #expect(try await fixture.value("document.querySelector('video').getAttribute('style')") as? String == "opacity:0.9")
        #expect(await fixture.view.requestMediaPlaybackState() == .playing)
    }

    @Test("A silent floating video stays awake while another tab is selected")
    func floatingPlayerDoesNotHibernate() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        #expect(await fixture.tab.toggleFloatingVideo())
        fixture.browser.newTab(url: nil)
        fixture.tab.snapshot.lastActiveAt = Date(timeIntervalSinceNow: -10_000)
        fixture.browser.sweepHibernation(now: .now, keeping: [])
        #expect(!fixture.tab.isHibernated)
        #expect(fixture.tab.isVideoFloating)
        #expect(fixture.view.window === fixture.tab.floatingVideoPanel)
    }

    @Test("Closing the source tab also closes the panel and suspends playback")
    func closingTabStopsFloatingPlayer() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        #expect(await fixture.tab.toggleFloatingVideo())
        let panel = try #require(fixture.tab.floatingVideoPanel)
        fixture.browser.close(fixture.tab.id)
        #expect(!panel.isVisible)
        #expect(fixture.tab.floatingVideoPanel == nil)
        #expect(!fixture.tab.isVideoFloating)
        #expect(await fixture.view.requestMediaPlaybackState() == .suspended)
    }

    @Test("Play, pause, and dismiss control the original player")
    func overlayControlsOriginalVideo() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        #expect(await fixture.tab.toggleFloatingVideo())
        await fixture.tab.toggleVideoPlayback()
        #expect(await fixture.settles { !fixture.tab.isVideoPlaying })
        await fixture.tab.toggleVideoPlayback()
        #expect(await fixture.settles { fixture.tab.isVideoPlaying })
        fixture.tab.closeFloatingVideo()
        #expect(!fixture.tab.isVideoFloating)
        #expect(try await fixture.value("document.querySelector('video').paused") as? Bool == true)
    }

    @Test("Starting navigation returns the floating player before the page changes")
    func navigationEndsFloatingPresentation() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        #expect(await fixture.tab.toggleFloatingVideo())
        fixture.tab.beginNavigation()
        #expect(!fixture.tab.isVideoFloating)
        #expect(fixture.view.window === fixture.window)
    }
}
