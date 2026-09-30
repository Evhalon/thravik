import AppKit
import SwiftUI

/// The borderless child window the suggestion rows live in. It never becomes
/// key: the page must keep the keyboard, or typing would stop mid-word.
@MainActor
final class FormSuggestionPanel {
    private var panel: NSPanel?
    private weak var parent: NSWindow?

    static let gap: CGFloat = 3
    static let widthRange: ClosedRange<CGFloat> = 200...440

    func show(rows: Int, under anchor: CGRect, in parent: NSWindow, content: () -> NSView) {
        let panel = self.panel ?? makePanel(content: content())
        self.panel = panel
        if self.parent !== parent {
            self.parent?.removeChildWindow(panel)
            parent.addChildWindow(panel, ordered: .above)
            self.parent = parent
        }
        panel.setFrame(frame(rows: rows, under: anchor, on: parent.screen), display: true)
        panel.orderFront(nil)
    }

    func hide() {
        guard let panel else { return }
        parent?.removeChildWindow(panel)
        parent = nil
        panel.orderOut(nil)
    }

    /// Under the field, or over it when the screen runs out below, as in Chrome.
    private func frame(rows: Int, under anchor: CGRect, on screen: NSScreen?) -> CGRect {
        let width = min(max(anchor.width, Self.widthRange.lowerBound), Self.widthRange.upperBound)
        let height = FormSuggestionList.height(forRows: rows)
        var frame = CGRect(x: anchor.minX, y: anchor.minY - Self.gap - height, width: width, height: height)
        if let visible = screen?.visibleFrame, frame.minY < visible.minY {
            frame.origin.y = anchor.maxY + Self.gap
        }
        return frame
    }

    private func makePanel(content: NSView) -> NSPanel {
        let panel = SuggestionWindow(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = true
        panel.contentView = content
        return panel
    }
}

private final class SuggestionWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Clicks land on the first try even though the panel is never key.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
