import AppKit
import WebKit

@MainActor
final class FloatingVideoPanel: NSPanel {
    var onDismiss: (() -> Void)?
    private let surface: FloatingVideoSurface
    private weak var originalParent: NSView?
    private weak var originalWindow: NSWindow?
    private let transition = FloatingVideoTransition()
    private var source: FloatingVideoSource?
    private(set) var isReturning = false

    init(view: WKWebView, aspectRatio: Double) {
        let host = WebViewHost.containing(view) ?? WebViewHost(webView: view)
        originalParent = host.superview
        originalWindow = host.window
        surface = FloatingVideoSurface(host: host)
        let screen = view.window?.screen ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1_280, height: 800)
        let width = min(400, visible.width * 0.45, visible.height * 0.6 * aspectRatio)
        let size = NSSize(width: width, height: width / aspectRatio)
        let frame = NSRect(x: visible.maxX - size.width - 24, y: visible.minY + 24,
                           width: size.width, height: size.height)
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel, .resizable],
                   backing: .buffered, defer: false)
        contentAspectRatio = NSSize(width: aspectRatio, height: 1)
        let minimumWidth = max(220, 124 * aspectRatio)
        contentMinSize = NSSize(width: minimumWidth, height: minimumWidth / aspectRatio)
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        contentView = surface
        surface.attachHost()
        setAccessibilityLabel("Floating video")
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func installControls(_ controls: NSView) { surface.installControls(controls) }

    func present(from source: FloatingVideoSource?) async {
        self.source = source
        let destination = frame
        surface.setTransitioning(true)
        if let source, source.isVisible { setFrame(source.frame, display: true) }
        orderFrontRegardless()
        guard await transition.animate(self, to: destination) else { return }
        surface.setTransitioning(false)
    }

    func returnToSource(completion: @escaping @MainActor () -> Void) {
        guard !isReturning else { return }
        isReturning = true
        surface.setTransitioning(true)
        Task { [weak self] in
            guard let self else { return }
            if let source, source.isVisible {
                guard await transition.animate(self, to: source.frame) else { return }
            }
            completion()
        }
    }

    func focusSource() {
        NSApp?.activate()
        originalWindow?.makeKeyAndOrderFront(nil)
    }

    func restore() {
        transition.cancel()
        surface.setTransitioning(false)
        surface.stopMotion()
        let host = surface.host
        host.removeFromSuperview()
        if let originalParent, originalParent.window === originalWindow {
            originalParent.addSubview(host)
            host.isHidden = false
            host.frame = originalParent.bounds
        } else {
            WebViewWindowPark.park(host, from: originalWindow)
        }
        onDismiss = nil
        orderOut(nil)
        close()
    }

    override func cancelOperation(_ sender: Any?) { onDismiss?() }

    override func orderOut(_ sender: Any?) {
        transition.cancel()
        surface.stopMotion()
        super.orderOut(sender)
    }
}
