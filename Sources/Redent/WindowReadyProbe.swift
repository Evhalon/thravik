import AppKit
import SwiftUI

/// Notifies the app only after SwiftUI attached this scene to its native window.
struct WindowReadyProbe: NSViewRepresentable {
    let onWindowReady: @MainActor (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        Host(onWindowReady: onWindowReady)
    }

    func updateNSView(_ view: NSView, context: Context) {
        guard let host = view as? Host else { return }
        host.onWindowReady = onWindowReady
        host.notifyIfReady()
    }
}

private final class Host: NSView {
    var onWindowReady: @MainActor (NSWindow) -> Void
    private weak var notifiedWindow: NSWindow?

    init(onWindowReady: @escaping @MainActor (NSWindow) -> Void) {
        self.onWindowReady = onWindowReady
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        notifyIfReady()
    }

    func notifyIfReady() {
        guard let window, window !== notifiedWindow else { return }
        notifiedWindow = window
        DispatchQueue.main.async { [weak self, weak window] in
            guard let self, let window, self.window === window else { return }
            self.onWindowReady(window)
        }
    }
}
