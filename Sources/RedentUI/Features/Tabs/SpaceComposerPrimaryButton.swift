import AppKit
import RedentDesign
import SwiftUI

/// Next / Create. A SwiftUI button drops the first click while the name field
/// is focused, and a sliding step can cover it. The click lands on an AppKit
/// view that runs the action immediately; Return stays a hidden shortcut.
struct SpaceComposerPrimaryButton: View {
    let title: String
    let enabled: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: Metric.controlHeight)
            .background(Capsule().fill(tint.opacity(enabled ? 0.9 : 0.3)))
            .contentShape(Capsule())
            .overlay { ComposerClickCatcher(enabled: enabled, action: action) }
            .background { returnKey }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, action)
    }

    /// Return still confirms. It must not take the click; the catcher does.
    private var returnKey: some View {
        Button(title, action: action)
            .keyboardShortcut(.defaultAction)
            .opacity(0)
            .allowsHitTesting(false)
            .disabled(!enabled)
            .accessibilityHidden(true)
    }
}

/// Fills the button and accepts the click even when a text field is first responder.
private struct ComposerClickCatcher: NSViewRepresentable {
    var enabled: Bool
    var action: () -> Void

    func makeNSView(context: Context) -> ComposerClickView {
        let view = ComposerClickView()
        view.enabled = enabled
        view.action = action
        return view
    }

    func updateNSView(_ view: ComposerClickView, context: Context) {
        view.enabled = enabled
        view.action = action
    }
}

private final class ComposerClickView: NSView {
    var enabled = true
    var action: () -> Void = {}

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        enabled && bounds.contains(point) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        guard enabled else { return }
        action()
    }
}
