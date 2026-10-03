import AppKit
import CoreGraphics
import Testing
@testable import RedentEngine

@Suite("Floating video gestures", .serialized)
@MainActor
struct FloatingVideoGestureTests {
    @Test("Two-finger motion moves the panel; system momentum cannot move it twice")
    func preciseScrollMovesPanel() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        #expect(await fixture.tab.toggleFloatingVideo())
        let panel = try #require(fixture.tab.floatingVideoPanel)
        let surface = try #require(panel.contentView as? FloatingVideoSurface)
        let screen = try #require(panel.screen)
        panel.setFrameOrigin(CGPoint(x: screen.visibleFrame.midX - panel.frame.width / 2,
                                     y: screen.visibleFrame.midY - panel.frame.height / 2))
        let start = panel.frame.origin
        let began = try scroll(phase: 1, deltaX: 0)
        surface.scrollWheel(with: began)
        let moved = try scroll(phase: 2, deltaX: -30)
        #expect(moved.hasPreciseScrollingDeltas)
        #expect(moved.phase.contains(.changed))
        surface.scrollWheel(with: moved)
        #expect(panel.frame.origin != start)
        let movedOrigin = panel.frame.origin
        surface.scrollWheel(with: try scroll(phase: 0, deltaX: -30, momentum: 2))
        #expect(panel.frame.origin == movedOrigin)
        surface.scrollWheel(with: try scroll(phase: 4, deltaX: 0))
        // The throw keeps coasting after the gesture ends. Wait for it to
        // actually move instead of a fixed delay, which loses the race when
        // the whole suite runs in parallel.
        if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            var coasted = panel.frame.origin != movedOrigin
            for _ in 0..<30 where !coasted {
                try await Task.sleep(for: .milliseconds(100))
                coasted = panel.frame.origin != movedOrigin
            }
            #expect(coasted)
        }
        surface.stopMotion()
    }

    @Test("Mouse wheel events do not turn ordinary scrolling into a throw")
    func lineScrollIsIgnored() async throws {
        let fixture = try await FloatingVideoFixture()
        defer { fixture.close() }
        #expect(await fixture.tab.toggleFloatingVideo())
        let panel = try #require(fixture.tab.floatingVideoPanel)
        let surface = try #require(panel.contentView as? FloatingVideoSurface)
        let start = panel.frame.origin
        let event = try scroll(phase: 0, deltaX: -30, precise: false)
        #expect(!event.hasPreciseScrollingDeltas)
        surface.scrollWheel(with: event)
        #expect(panel.frame.origin == start)
    }

    private func scroll(phase: Int64, deltaX: Int32, momentum: Int64 = 0, precise: Bool = true) throws -> NSEvent {
        let event = try #require(CGEvent(scrollWheelEvent2Source: nil,
            units: precise ? .pixel : .line, wheelCount: 2, wheel1: 0, wheel2: deltaX, wheel3: 0))
        event.timestamp = UInt64(ProcessInfo.processInfo.systemUptime * 1e9)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: precise ? 1 : 0)
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: phase)
        event.setIntegerValueField(.scrollWheelEventMomentumPhase, value: momentum)
        return try #require(NSEvent(cgEvent: event))
    }
}
