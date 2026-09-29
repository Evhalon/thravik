import AppKit
import Testing
@testable import RedentEngine

@Suite("Floating video resizing", .serialized)
@MainActor
struct FloatingVideoResizeTests {
    @Test("The resize grip changes the existing video host while preserving its aspect")
    func gripResizesOriginalHost() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        #expect(await fixture.tab.toggleFloatingVideo())
        let panel = try #require(fixture.tab.floatingVideoPanel)
        let surface = try #require(panel.contentView as? FloatingVideoSurface)
        let grip = try #require(surface.subviews.compactMap { $0 as? FloatingVideoResizeHandle }.first)
        panel.setFrameOrigin(CGPoint(x: 200, y: 300))
        surface.layoutSubtreeIfNeeded()
        let original = panel.frame
        let location = CGPoint(x: original.width - 16, y: 16)
        grip.mouseDown(with: try mouse(.leftMouseDown, at: location, window: panel))
        grip.mouseDragged(with: try mouse(.leftMouseDragged,
            at: CGPoint(x: location.x + 80, y: location.y), window: panel))
        grip.mouseUp(with: try mouse(.leftMouseUp, at: location, window: panel))
        surface.layoutSubtreeIfNeeded()
        #expect(panel.styleMask.contains(.resizable))
        #expect(panel.frame.width > original.width)
        #expect(panel.frame.minX == original.minX)
        #expect(panel.frame.maxY == original.maxY)
        #expect(abs(panel.frame.width / panel.frame.height - original.width / original.height) < 0.001)
        #expect(surface.host.frame.size == surface.bounds.size)
        #expect(surface.host.webView === fixture.view)
    }

    private func mouse(_ type: NSEvent.EventType, at point: CGPoint, window: NSWindow) throws -> NSEvent {
        try #require(NSEvent.mouseEvent(with: type, location: point, modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
            context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
    }
}
