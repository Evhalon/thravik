import AppKit
import Testing
@testable import RedentEngine

@Suite("Video overlay affordance", .serialized)
@MainActor
struct VideoAffordanceTests {
    @Test("The Float video button stays visible without hovering or browser chrome")
    func videoShowsAffordance() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        #expect(try await fixture.value("!document.querySelector('[data-redent-video-affordance]').hidden") as? Bool == true)
        let placement = try await fixture.value("""
        (() => {
            const button = document.querySelector('[data-redent-video-affordance]');
            const video = document.querySelector('video').getBoundingClientRect();
            const rect = button.getBoundingClientRect();
            const contained = rect.width > 0 && rect.height > 0 && rect.left >= video.left &&
                rect.right <= video.right && rect.top >= video.top && rect.bottom <= video.bottom;
            return contained ? 'contained' : JSON.stringify({ button: rect, video });
        })()
        """) as? String
        #expect(placement == "contained")
        _ = try await fixture.value("document.dispatchEvent(new PointerEvent('pointerleave'))")
        #expect(try await fixture.value("!document.querySelector('[data-redent-video-affordance]').hidden") as? Bool == true)
        #expect(await fixture.tab.toggleFloatingVideo())
        #expect(try await fixture.value("document.querySelector('[data-redent-video-affordance]').hidden") as? Bool == true)
        fixture.tab.returnVideoToTab()
        #expect(await fixture.settles { !fixture.tab.isVideoFloating })
        _ = try await fixture.value("document.dispatchEvent(new Event('scroll'))")
        #expect(try await fixture.value("!document.querySelector('[data-redent-video-affordance]').hidden") as? Bool == true)
    }

    @Test("A page cannot float its player by synthesizing a click on the button")
    func syntheticClickDoesNotFloat() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        _ = try await fixture.value("document.querySelector('[data-redent-video-affordance]').click()")
        #expect(!fixture.tab.isVideoFloating)
    }

    @Test("Scrolling a video out of view hides the overlay instead of covering other content")
    func offscreenVideoHidesAffordance() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        _ = try await fixture.value("""
        (() => {
            document.querySelector('video').style.transform = 'translateY(-2000px)';
            document.dispatchEvent(new Event('scroll'));
            return true;
        })()
        """)
        #expect(try await fixture.value("document.querySelector('[data-redent-video-affordance]').hidden") as? Bool == true)
    }
}
