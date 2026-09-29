import AppKit
import RedentKit

@MainActor
final class FloatingVideoTransition {
    private var animation: Task<Bool, Never>?
    private var generation: UInt = 0
    private(set) var isAnimating = false

    func animate(_ window: NSWindow, to target: CGRect) async -> Bool {
        cancel()
        let request = generation
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            window.setFrame(target, display: true)
            return true
        }
        let initial = window.frame
        isAnimating = true
        let task = Task { [weak window] in
            let clock = ContinuousClock()
            let start = clock.now
            while !Task.isCancelled {
                guard let window else { return false }
                let elapsed = start.duration(to: clock.now).components
                let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
                let fraction = min(seconds / 0.32, 1)
                let progress = FloatingVideoEasing.progress(fraction)
                window.setFrame(Self.frame(from: initial, to: target, progress: progress), display: true)
                if fraction == 1 { return true }
                try? await Task.sleep(for: .milliseconds(8))
            }
            return false
        }
        animation = task
        let finished = await task.value
        guard request == generation else { return false }
        isAnimating = false
        animation = nil
        return finished
    }

    func cancel() {
        generation &+= 1
        animation?.cancel()
        animation = nil
        isAnimating = false
    }

    private static func frame(from initial: CGRect, to target: CGRect, progress: Double) -> CGRect {
        CGRect(x: initial.minX + (target.minX - initial.minX) * progress,
               y: initial.minY + (target.minY - initial.minY) * progress,
               width: initial.width + (target.width - initial.width) * progress,
               height: initial.height + (target.height - initial.height) * progress)
    }
}
