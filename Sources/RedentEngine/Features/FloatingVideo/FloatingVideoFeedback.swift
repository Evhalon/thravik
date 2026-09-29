import AppKit
import CoreGraphics

@MainActor
struct FloatingVideoFeedback {
    var capture: () -> Bool
    var release: () -> Void
    var follow: (CGPoint) -> Void
    var pickup: () -> Void

    static var system: Self {
        Self(capture: {
            guard let application = NSApp else { return false }
            application.activate()
            _ = CGAssociateMouseAndMouseCursorPosition(0)
            NSCursor.hide()
            return true
        }, release: {
            _ = CGAssociateMouseAndMouseCursorPosition(1)
            NSCursor.unhide()
        }, follow: { point in
            let desktopTop = NSScreen.screens.first?.frame.maxY ?? 0
            _ = CGWarpMouseCursorPosition(CGPoint(x: point.x, y: desktopTop - point.y))
        }, pickup: {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        })
    }
}
