import AppKit
import CoreGraphics
import Testing
@testable import RedentEngine

@Suite("Floating video drag input", .serialized)
@MainActor
struct FloatingVideoDragInputTests {
    @Test("Two-finger movement is 30 percent slower than the previous three-times gain")
    func trackpadMovementIsAmplified() throws {
        let window = makeWindow()
        let feedback = InputFeedbackSpy()
        let interaction = FloatingVideoInteraction(feedback: feedback.actions)
        defer { interaction.stop(); window.close() }
        interaction.scroll(try scroll(phase: 1), in: window)
        let origin = window.frame.origin
        let event = try scroll(phase: 2, deltaX: -20, deltaY: 10)
        interaction.scroll(event, in: window)
        #expect(abs(window.frame.minX - origin.x) == abs(event.scrollingDeltaX) * 2.1)
        #expect(abs(window.frame.minY - origin.y) == abs(event.scrollingDeltaY) * 2.1)
        #expect(feedback.captures == 1)
        #expect(feedback.haptics == 1)
    }

    @Test("Click-and-drag lifts the player and keeps the cursor visible until mouse-up")
    func mouseKeepsPointerAndHold() async {
        let window = makeWindow()
        let feedback = InputFeedbackSpy()
        let interaction = FloatingVideoInteraction(feedback: feedback.actions)
        defer { interaction.stop(); window.close() }
        let original = window.frame
        interaction.begin(window, at: ProcessInfo.processInfo.systemUptime, trackpad: false)
        interaction.touches(2)
        interaction.touches(0)
        #expect(interaction.isHeld)
        interaction.move(window, delta: CGSize(width: 30, height: 20), at: ProcessInfo.processInfo.systemUptime)
        #expect(window.frame.minX - original.minX == 30)
        #expect(window.frame.minY - original.minY == 20)
        #expect(await settles { abs(window.frame.width - original.width * 1.045) <= 1 })
        #expect(feedback.haptics == 1)
        #expect(feedback.captures == 0)
        #expect(feedback.positions.isEmpty)
        interaction.finish(window)
        #expect(!interaction.isHeld)
        #expect(await settles { window.frame.width == original.width })
        #expect(feedback.releases == 0)
    }

    @Test("A scroll event cannot steal a held click drag")
    func scrollDoesNotStealMouse() throws {
        let window = makeWindow()
        let feedback = InputFeedbackSpy()
        let interaction = FloatingVideoInteraction(feedback: feedback.actions)
        defer { interaction.stop(); window.close() }
        interaction.begin(window, at: ProcessInfo.processInfo.systemUptime, trackpad: false)
        let origin = window.frame.origin
        interaction.scroll(try scroll(phase: 1, deltaX: -40), in: window)
        interaction.scroll(try scroll(phase: 4), in: window)
        #expect(window.frame.origin == origin)
        #expect(interaction.isHeld)
        #expect(feedback.captures == 0)
    }

    private func makeWindow() -> NSWindow {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1_280, height: 800)
        let window = NSWindow(contentRect: NSRect(x: screen.midX - 200, y: screen.midY - 112,
            width: 400, height: 225), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        return window
    }

    private func settles(_ condition: () -> Bool) async -> Bool {
        for _ in 0..<250 {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return false
    }

    private func scroll(phase: Int64, deltaX: Int32 = 0, deltaY: Int32 = 0) throws -> NSEvent {
        let event = try #require(CGEvent(scrollWheelEvent2Source: nil,
            units: .pixel, wheelCount: 2, wheel1: deltaY, wheel2: deltaX, wheel3: 0))
        event.timestamp = UInt64(ProcessInfo.processInfo.systemUptime * 1e9)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: phase)
        return try #require(NSEvent(cgEvent: event))
    }
}

@MainActor
private final class InputFeedbackSpy {
    var captures = 0
    var releases = 0
    var haptics = 0
    var positions: [CGPoint] = []

    var actions: FloatingVideoFeedback {
        FloatingVideoFeedback(capture: { self.captures += 1; return true },
            release: { self.releases += 1 }, follow: { self.positions.append($0) }, pickup: { self.haptics += 1 })
    }
}
