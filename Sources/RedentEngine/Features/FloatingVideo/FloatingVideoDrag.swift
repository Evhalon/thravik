import AppKit
import RedentKit

@MainActor
final class FloatingVideoDrag {
    private var velocity = CGSize.zero
    private var lastTime: TimeInterval = 0
    private var animation: Task<Void, Never>?
    private let screens: () -> [CGRect]

    init(screens: @escaping () -> [CGRect] = { NSScreen.screens.map(\.visibleFrame) }) {
        self.screens = screens
    }

    func begin(at timestamp: TimeInterval) {
        cancel()
        velocity = .zero
        lastTime = timestamp
    }

    func move(_ window: NSWindow, delta: CGSize, at timestamp: TimeInterval) {
        guard delta.width != 0 || delta.height != 0 else { return }
        cancel()
        let interval = min(max(timestamp - lastTime, 1.0 / 120), 0.1)
        velocity = CGSize(width: delta.width / interval, height: delta.height / interval)
        lastTime = timestamp
        var frame = window.frame
        frame.origin.x += delta.width
        frame.origin.y += delta.height
        // A held player must straddle display edges before its center reaches the next display.
        window.setFrameOrigin(frame.origin)
    }

    func finish(_ window: NSWindow, throwing: Bool = true,
                place: @escaping (NSWindow, CGPoint, TimeInterval) -> Void = { window, origin, _ in
                    window.setFrameOrigin(origin)
                }) {
        let recent = ProcessInfo.processInfo.systemUptime - lastTime < 0.15
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let motion = FloatingVideoMotion(frame: window.frame,
            velocity: throwing && recent && !reduceMotion ? velocity : .zero, screens: screens())
        guard !reduceMotion else {
            place(window, motion.target, FloatingVideoMotion.duration)
            return
        }
        animation = Task { [weak window] in
            let clock = ContinuousClock()
            let start = clock.now
            while !Task.isCancelled {
                let duration = start.duration(to: clock.now).components
                let elapsed = Double(duration.seconds) + Double(duration.attoseconds) / 1e18
                guard let window else { return }
                place(window, motion.position(at: elapsed), elapsed)
                if elapsed >= FloatingVideoMotion.duration { return }
                try? await Task.sleep(for: .milliseconds(8))
            }
        }
    }

    func cancel() { animation?.cancel(); animation = nil }
}
