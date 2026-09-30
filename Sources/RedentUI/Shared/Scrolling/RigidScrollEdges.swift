import AppKit
import SwiftUI

/// Stops the enclosing `NSScrollView` from rubber-banding past its ends.
///
/// SwiftUI's `scrollBounceBehavior` still bounces whenever the content
/// overflows, and a list that springs past its top slides under whatever
/// sits above it. Placed inside the scroll view's content so AppKit can
/// find the scroll view it lives in.
struct RigidScrollEdges: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let probe = NSView()
        DispatchQueue.main.async { configure(probe.enclosingScrollView) }
        return probe
    }

    func updateNSView(_ view: NSView, context: Context) {
        configure(view.enclosingScrollView)
    }

    private func configure(_ scrollView: NSScrollView?) {
        guard let scrollView else { return }
        if scrollView.verticalScrollElasticity != .none { scrollView.verticalScrollElasticity = .none }
        if scrollView.horizontalScrollElasticity != .none { scrollView.horizontalScrollElasticity = .none }
    }
}
