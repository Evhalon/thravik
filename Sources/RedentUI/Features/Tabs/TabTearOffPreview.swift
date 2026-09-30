import AppKit
import RedentKit
import SwiftUI

/// Carries a dragged tab past its window's edge.
///
/// SwiftUI cannot draw outside its window, so the tab rides in a borderless,
/// click-through panel of its own that follows the pointer until the drag
/// ends or comes back inside.
@MainActor
final class TabTearOffPreview {
    private var panel: NSPanel?

    func follow(_ tab: any BrowserTab, to pointer: CGPoint) {
        let panel = self.panel ?? present(tab)
        let height = panel.frame.height
        let grip = TabTearOffCard.grip
        panel.setFrameOrigin(NSPoint(x: pointer.x - grip.x, y: pointer.y - height + grip.y))
    }

    func hide() {
        guard let panel else { return }
        self.panel = nil
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            panel.animator().alphaValue = 0
        }
        Task {
            try? await Task.sleep(for: .milliseconds(160))
            panel.orderOut(nil)
        }
    }

    private func present(_ tab: any BrowserTab) -> NSPanel {
        let card = TabTearOffCard(
            title: tab.snapshot.displayTitle,
            faviconData: tab.snapshot.faviconData,
            host: tab.origin?.displayHost
        )
        let inset = TabTearOffCard.inset * 2
        let size = NSSize(width: TabTearOffCard.size.width + inset, height: TabTearOffCard.size.height + inset)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        panel.contentView = NSHostingView(rootView: card)
        panel.orderFrontRegardless()
        self.panel = panel
        return panel
    }
}
