import AppKit
import WebKit

@MainActor
final class FloatingVideoSource {
    private weak var window: NSWindow?
    private let frameInWindow: CGRect
    private let initialFrame: CGRect

    init?(bounds: [String: Any], view: WKWebView) {
        guard let window = view.window,
              let x = bounds["x"] as? Double, x.isFinite,
              let y = bounds["y"] as? Double, y.isFinite,
              let width = bounds["width"] as? Double, width.isFinite, width > 0,
              let height = bounds["height"] as? Double, height.isFinite, height > 0,
              let viewport = bounds["viewportWidth"] as? Double, viewport.isFinite, viewport > 0 else { return nil }
        let scale = view.bounds.width / viewport
        let rect = CGRect(x: x * scale, y: y * scale, width: width * scale, height: height * scale)
        let visible = rect.intersection(view.bounds)
        guard !visible.isNull, !visible.isEmpty else { return nil }
        frameInWindow = view.convert(visible, to: nil)
        initialFrame = window.convertToScreen(frameInWindow)
        self.window = window
    }

    var frame: CGRect { window?.convertToScreen(frameInWindow) ?? initialFrame }
    var isVisible: Bool { window?.isVisible == true && window?.isMiniaturized == false }
}
