import AppKit
import RedentKit

@MainActor
final class FloatingVideoPickup {
    private var restingSize: CGSize?
    private var animation: Task<Void, Never>?
    private var raised: CGFloat = 0
    private var roundingResidual = CGPoint.zero
    private var release: FloatingVideoRelease?
    private var releaseLift: CGFloat = 0

    func begin(_ window: NSWindow) {
        release = nil
        let size = restingSize ?? window.frame.size
        restingSize = size
        animate(window, to: CGSize(width: size.width * 1.045, height: size.height * 1.045), lift: 8)
    }

    func finish(_ window: NSWindow) {
        guard let restingSize else { return }
        animation?.cancel()
        animation = nil
        releaseLift = raised
        release = FloatingVideoRelease(frame: window.frame, restingSize: restingSize, lift: raised)
    }

    func place(_ window: NSWindow, at origin: CGPoint, elapsed: TimeInterval) {
        guard let release else { window.setFrameOrigin(origin); return }
        var frame = release.frame(at: origin, elapsed: elapsed)
        frame.origin = CGPoint(x: frame.origin.x.rounded(), y: frame.origin.y.rounded())
        frame.size = CGSize(width: frame.width.rounded(), height: frame.height.rounded())
        raised = releaseLift * (1 - release.progress(at: elapsed))
        if release.progress(at: elapsed) == 1 { restingSize = nil }
        window.setFrame(frame, display: true)
    }

    func cancel(_ window: NSWindow?) {
        animation?.cancel()
        animation = nil
        if let window, let restingSize { apply(window, size: restingSize, lift: 0) }
        restingSize = nil
        roundingResidual = .zero
        release = nil
    }

    private func animate(_ window: NSWindow, to target: CGSize, lift: CGFloat) {
        animation?.cancel()
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            apply(window, size: target, lift: 0)
            return
        }
        let size = window.frame.size
        let initialLift = raised
        animation = Task { [weak self, weak window] in
            let clock = ContinuousClock()
            let start = clock.now
            while !Task.isCancelled {
                guard let self, let window else { return }
                let elapsed = start.duration(to: clock.now).components
                let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
                let progress = min(seconds / 0.18, 1)
                let eased = CGFloat(FloatingVideoEasing.progress(progress))
                self.apply(window, size: CGSize(width: size.width + (target.width - size.width) * eased,
                    height: size.height + (target.height - size.height) * eased),
                    lift: initialLift + (lift - initialLift) * eased)
                if progress == 1 { return }
                try? await Task.sleep(for: .milliseconds(8))
            }
        }
    }

    private func apply(_ window: NSWindow, size: CGSize, lift: CGFloat) {
        var frame = window.frame
        let alignedSize = CGSize(width: size.width.rounded(), height: size.height.rounded())
        frame.origin.x -= (alignedSize.width - frame.width) / 2
        frame.origin.y -= (alignedSize.height - frame.height) / 2
        frame.origin.y += lift - raised
        // AppKit rounds frame edges independently; integral geometry avoids growth on release.
        frame.origin.x += roundingResidual.x
        frame.origin.y += roundingResidual.y
        let preciseOrigin = frame.origin
        frame.origin = CGPoint(x: frame.origin.x.rounded(), y: frame.origin.y.rounded())
        roundingResidual = CGPoint(x: preciseOrigin.x - frame.origin.x, y: preciseOrigin.y - frame.origin.y)
        frame.size = alignedSize
        raised = lift
        window.setFrame(frame, display: true)
    }
}
