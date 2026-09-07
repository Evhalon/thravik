import AppKit
import SwiftUI

/// A real backdrop blur, sampled from what is *behind* the window.
///
/// SwiftUI's `Material` only blurs content inside the app, which on a browser
/// means blurring the web page and nothing else. Going through
/// `NSVisualEffectView` with `.behindWindow` blending is what makes the chrome
/// feel like frosted glass sitting on the desktop rather than a grey rectangle.
public struct VisualEffectBackdrop: NSViewRepresentable {
    public enum Depth: Equatable {
        /// The chrome slab — the deepest, most diffuse blur.
        case chrome
        /// The titlebar strip — same desktop sample, not emphasized, so the
        /// wallpaper still reads through instead of collapsing to grey glass.
        case titlebar
        /// Floating elements that sit above the page: pills, prompts, menus.
        case floating

        var material: NSVisualEffectView.Material {
            switch self {
            case .chrome, .titlebar: .underWindowBackground
            case .floating: .hudWindow
            }
        }

        /// The chrome slab frosts the desktop behind the window; anything
        /// floating over a page must frost *the page*, or it samples the
        /// wallpaper and comes out as a grey slab sitting on dark content.
        var blending: NSVisualEffectView.BlendingMode {
            switch self {
            case .chrome, .titlebar: .behindWindow
            case .floating: .withinWindow
            }
        }

        var isEmphasized: Bool {
            self != .titlebar
        }
    }

    private let depth: Depth

    public init(_ depth: Depth = .chrome) {
        self.depth = depth
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = depth.material
        view.blendingMode = depth.blending
        view.state = .followsWindowActiveState
        view.isEmphasized = depth.isEmphasized
        return view
    }

    public func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = depth.material
        view.blendingMode = depth.blending
        view.isEmphasized = depth.isEmphasized
    }
}
