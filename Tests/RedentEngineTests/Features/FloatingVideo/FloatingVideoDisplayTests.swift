import AppKit
import Foundation
import Testing
@testable import RedentEngine

@Suite("Floating video display crossing", .serialized)
@MainActor
struct FloatingVideoDisplayTests {
    @Test("Dragging crosses a display seam without clamping to the original window screen")
    func crossesDisplay() async throws {
        let main = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1_440, height: 900)
        let second = NSRect(x: main.maxX, y: main.minY, width: main.width, height: main.height)
        let window = makeWindow(at: CGPoint(x: main.maxX - 424, y: main.midY - 112))
        let driver = FloatingVideoDrag(screens: { [main, second] })
        defer { driver.cancel(); window.close() }
        let timestamp = ProcessInfo.processInfo.systemUptime
        driver.begin(at: timestamp)
        driver.move(window, delta: CGSize(width: 300, height: 0), at: timestamp + 0.01)
        #expect(window.frame.minX == main.maxX - 124)
        driver.move(window, delta: CGSize(width: 300, height: 0), at: timestamp + 0.02)
        #expect(window.frame.minX == main.maxX + 176)
        driver.finish(window, throwing: false)
        try await Task.sleep(for: .milliseconds(500))
        #expect(second.contains(window.frame))
    }

    @Test("Releasing after a display disconnect restores the panel to a connected display")
    func recoversMissingDisplay() async throws {
        let main = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1_440, height: 900)
        let window = makeWindow(at: CGPoint(x: main.maxX + 800, y: main.midY - 112))
        let driver = FloatingVideoDrag(screens: { [main] })
        defer { driver.cancel(); window.close() }
        driver.begin(at: ProcessInfo.processInfo.systemUptime)
        let original = window.frame.origin
        driver.finish(window, throwing: false)
        if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            #expect(window.frame.origin == original)
        }
        try await Task.sleep(for: .milliseconds(500))
        #expect(main.contains(window.frame))
    }

    private func makeWindow(at origin: CGPoint) -> NSWindow {
        let window = NSWindow(contentRect: NSRect(origin: origin, size: NSSize(width: 400, height: 225)),
            styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        return window
    }
}
