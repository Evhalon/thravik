import AppKit
import CoreGraphics
import Testing
@testable import RedentEngine

@Suite("Floating video pickup", .serialized)
@MainActor
struct FloatingVideoInteractionTests {
    @Test("The pointer stays captured through a stationary hold until fingers lift")
    func heldUntilRelease() async throws {
        let window = makeWindow()
        let feedback = VideoFeedbackSpy()
        let interaction = FloatingVideoInteraction(feedback: feedback.actions)
        defer { interaction.stop(); window.close() }
        let originalSize = window.frame.size
        interaction.touches(2)
        interaction.scroll(try scroll(phase: 1), in: window)
        #expect(await settles { abs(window.frame.width - originalSize.width * 1.045) <= 1 })
        // AppKit rounds borderless frames outward to screen pixels.
        let proportionalHeight = window.frame.width * originalSize.height / originalSize.width
        #expect(abs(window.frame.height - proportionalHeight) <= 1)
        let origin = window.frame.origin
        interaction.scroll(try scroll(phase: 4), in: window)
        #expect(interaction.isHeld)
        interaction.scroll(try scroll(phase: 2, deltaX: -30), in: window)
        #expect(window.frame.origin != origin)
        #expect(feedback.captures == 1)
        #expect(feedback.haptics == 1)
        #expect(feedback.releases == 0)
        #expect(window.frame.contains(try #require(feedback.positions.last)))
        interaction.touches(0)
        #expect(!interaction.isHeld)
        #expect(feedback.releases == 1)
        #expect(await settles { abs(window.frame.width - originalSize.width) < 0.001 })
    }

    @Test("Cancel and teardown restore the cursor exactly once")
    func interruptedHoldRestoresPointer() throws {
        let window = makeWindow()
        let feedback = VideoFeedbackSpy()
        let interaction = FloatingVideoInteraction(feedback: feedback.actions)
        defer { interaction.stop(); window.close() }
        interaction.scroll(try scroll(phase: 1), in: window)
        interaction.scroll(try scroll(phase: 8), in: window)
        #expect(!interaction.isHeld)
        #expect(feedback.releases == 1)
        interaction.scroll(try scroll(phase: 1), in: window)
        interaction.stop()
        #expect(!interaction.isHeld)
        #expect(feedback.releases == 2)
        interaction.stop()
        #expect(feedback.releases == 2)
    }

    @Test("Regrabbing during release does not compound the pickup size")
    func regrabKeepsRestingSize() async throws {
        let window = makeWindow()
        let originalSize = window.frame.size
        let interaction = FloatingVideoInteraction(feedback: VideoFeedbackSpy().actions)
        defer { interaction.stop(); window.close() }
        interaction.begin(window, at: ProcessInfo.processInfo.systemUptime)
        #expect(await settles { abs(window.frame.width - originalSize.width * 1.045) <= 1 })
        interaction.finish(window, throwing: false)
        interaction.begin(window, at: ProcessInfo.processInfo.systemUptime)
        #expect(await settles { abs(window.frame.width - originalSize.width * 1.045) <= 1 })
        interaction.stop()
        #expect(abs(window.frame.width - originalSize.width) < 0.001)
    }

    @Test("A stationary pickup lifts and settles around the same center")
    func stationaryPickupDoesNotDrift() async throws {
        let window = makeWindow()
        let original = window.frame
        let interaction = FloatingVideoInteraction(feedback: VideoFeedbackSpy().actions)
        defer { interaction.stop(); window.close() }
        interaction.begin(window, at: ProcessInfo.processInfo.systemUptime)
        #expect(await settles { abs(window.frame.width - original.width * 1.045) <= 1 })
        #expect(abs(window.frame.midX - original.midX) <= 1)
        if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            #expect(window.frame.midY >= original.midY + 6)
        }
        interaction.finish(window, throwing: false)
        #expect(await settles {
            window.frame.size == original.size && abs(window.frame.midY - original.midY) <= 1
        })
        try await Task.sleep(for: .milliseconds(850))
        #expect(abs(window.frame.midX - original.midX) <= 1)
        #expect(abs(window.frame.midY - original.midY) <= 1)
    }

    private func makeWindow() -> NSWindow {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1_280, height: 800)
        let window = NSWindow(contentRect: NSRect(x: screen.midX - 200, y: screen.midY - 112.5,
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

    private func scroll(phase: Int64, deltaX: Int32 = 0) throws -> NSEvent {
        let event = try #require(CGEvent(scrollWheelEvent2Source: nil,
            units: .pixel, wheelCount: 2, wheel1: 0, wheel2: deltaX, wheel3: 0))
        event.timestamp = UInt64(ProcessInfo.processInfo.systemUptime * 1e9)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: phase)
        return try #require(NSEvent(cgEvent: event))
    }
}

@MainActor
private final class VideoFeedbackSpy {
    var captures = 0
    var releases = 0
    var haptics = 0
    var positions: [CGPoint] = []

    var actions: FloatingVideoFeedback {
        FloatingVideoFeedback(capture: { self.captures += 1; return true },
            release: { self.releases += 1 }, follow: { self.positions.append($0) }, pickup: { self.haptics += 1 })
    }
}
