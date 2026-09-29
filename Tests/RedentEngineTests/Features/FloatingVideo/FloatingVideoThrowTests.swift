import AppKit
import Foundation
import Testing
@testable import RedentEngine

@Suite("Floating video throw continuity", .serialized)
@MainActor
struct FloatingVideoThrowTests {
    @Test("A zero-delta event just before release cannot erase the throw velocity")
    func zeroDeltaKeepsRecentVelocity() async {
        let window = makeWindow()
        let drag = FloatingVideoDrag()
        defer { drag.cancel(); window.close() }
        let timestamp = ProcessInfo.processInfo.systemUptime
        drag.begin(at: timestamp - 1.0 / 60)
        drag.move(window, delta: CGSize(width: 20, height: 0), at: timestamp)
        let origin = window.frame.origin
        drag.move(window, delta: .zero, at: timestamp + 0.001)
        drag.finish(window)
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            #expect(window.frame.origin == origin)
        } else {
            #expect(await settles { window.frame.minX > origin.x + 5 })
        }
    }

    @Test("Resting fingers still suppress an old throw after movement has stopped")
    func zeroDeltaDoesNotRefreshOldVelocity() async {
        let window = makeWindow()
        let drag = FloatingVideoDrag()
        defer { drag.cancel(); window.close() }
        let timestamp = ProcessInfo.processInfo.systemUptime
        drag.begin(at: timestamp - 0.6)
        drag.move(window, delta: CGSize(width: 20, height: 0), at: timestamp - 0.5)
        let origin = window.frame.origin
        drag.move(window, delta: .zero, at: timestamp)
        drag.finish(window)
        try? await Task.sleep(for: .milliseconds(500))
        #expect(window.frame.origin == origin)
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
}
