import AppKit

final class ShortcutCaptureView: NSView {
    var onEvent: ((NSEvent) -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        tearDown()
        guard window != nil else { return }
        // Keys typed into another window must still reach it.
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            self.onEvent?(event)
            return nil
        }
    }

    override func removeFromSuperview() {
        tearDown()
        super.removeFromSuperview()
    }

    private func tearDown() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
