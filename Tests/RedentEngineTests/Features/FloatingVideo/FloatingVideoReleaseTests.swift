import AppKit
import Foundation
import RedentKit
import Testing
@testable import RedentEngine

@Suite("Floating video unified release", .serialized)
@MainActor
struct FloatingVideoReleaseTests {
    @Test("One release frame moves the panel and shrinks it together")
    func releaseRendersOneMovingFrame() async {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1_280, height: 800)
        let window = NSWindow(contentRect: NSRect(x: screen.midX - 200, y: screen.midY - 112,
            width: 400, height: 225), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let pickup = FloatingVideoPickup()
        defer { pickup.cancel(window); window.close() }
        let original = window.frame
        pickup.begin(window)
        #expect(await settles { abs(window.frame.width - original.width * 1.045) <= 1 })
        let held = window.frame
        pickup.finish(window)
        for step in 0...4 {
            let fraction = Double(step) / 4
            pickup.place(window, at: CGPoint(x: held.minX + 100 * fraction, y: held.minY),
                elapsed: FloatingVideoRelease.duration * fraction)
            #expect(abs(window.frame.midX - (held.midX + 100 * fraction)) <= 1)
            let width = held.width + (original.width - held.width) * fraction
            #expect(abs(window.frame.width - width) <= 1)
        }
        #expect(window.frame.size == original.size)
    }

    private func settles(_ condition: () -> Bool) async -> Bool {
        for _ in 0..<250 {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return false
    }
}
