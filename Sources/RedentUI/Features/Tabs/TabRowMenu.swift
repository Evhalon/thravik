import RedentKit
import SwiftUI

/// The right-click menu shared by both tab strips.
struct TabRowMenu: View {
    let tab: any BrowserTab
    let actions: TabRowActions

    var body: some View {
        Button(tab.isPinned ? "Unpin Tab" : "Pin Tab", action: actions.onTogglePin)
        Button(tab.isMuted ? "Unmute Tab" : "Mute Tab") { tab.setMuted(!tab.isMuted) }
        if let onDuplicate = actions.onDuplicate {
            Button("Duplicate Tab", action: onDuplicate)
        }
        if let onSplit = actions.onSplit {
            Button("Open in Split View", action: onSplit)
        }
        if let onUnsplit = actions.onUnsplit {
            Button("Remove from Split View", action: onUnsplit)
        }
        if let onUngroup = actions.onUngroup {
            Button("Remove from Group", action: onUngroup)
        }
        Divider()
        Button("Close Tab", action: actions.onClose)
            .keyboardShortcut("w")
        if let onCloseOthers = actions.onCloseOthers {
            Button("Close Other Tabs", action: onCloseOthers)
        }
    }
}
