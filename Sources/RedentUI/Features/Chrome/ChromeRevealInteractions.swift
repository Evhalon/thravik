import AppKit
import SwiftUI

/// A panel must stay mounted while its field, menu or popover is in use.
struct ChromeRevealInteractions: ViewModifier {
    let model: BrowserModel
    let reveal: ChromeRevealModel
    @State private var trackedPresentations = 0

    func body(content: Content) -> some View {
        content
            .onChange(of: isLocked, initial: true) { _, locked in reveal.setLocked(locked) }
            .onReceive(NotificationCenter.default.publisher(for: NSMenu.didBeginTrackingNotification)) { _ in
                trackedPresentations += 1
            }
            .onReceive(NotificationCenter.default.publisher(for: NSMenu.didEndTrackingNotification)) { _ in
                trackedPresentations = max(0, trackedPresentations - 1)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSPopover.willShowNotification)) { _ in
                trackedPresentations += 1
            }
            .onReceive(NotificationCenter.default.publisher(for: NSPopover.didCloseNotification)) { _ in
                trackedPresentations = max(0, trackedPresentations - 1)
            }
    }

    private var isLocked: Bool {
        model.address.isEditing || model.sheet != nil || model.showsCommandBar || trackedPresentations > 0
    }
}
