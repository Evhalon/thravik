import RedentKit
import SwiftUI

/// The right-click menu shared by both tab strips.
struct TabRowMenu: View {
    let tab: any BrowserTab
    let actions: TabRowActions
    let onSetEmojiIcon: () -> Void
    @Environment(\.shortcutBindings) private var bindings

    var body: some View {
        Button(tab.isPinned ? "Unpin Tab" : "Pin Tab", action: actions.onTogglePin)
            .shortcut(.pinTab, bindings: bindings)
        Button(tab.isMuted ? "Unmute Tab" : "Mute Tab") { tab.setMuted(!tab.isMuted) }
            .shortcut(.muteTab, bindings: bindings)
        if let onDuplicate = actions.onDuplicate {
            Button("Duplicate Tab", action: onDuplicate)
                .shortcut(.duplicateTab, bindings: bindings)
        }
        if let onSplit = actions.onSplit {
            Button("Open in Split View", action: onSplit)
                .shortcut(.splitView, bindings: bindings)
        }
        if let onUnsplit = actions.onUnsplit {
            Button("Remove from Split View", action: onUnsplit)
        }
        if let onUngroup = actions.onUngroup {
            Button("Remove from Group", action: onUngroup)
        }
        Divider()
        TabEmojiMenuItems(tab: tab, onPick: onSetEmojiIcon)
        Divider()
        Button("Close Tab", action: actions.onClose)
            .shortcut(.closeTab, bindings: bindings)
        if let onCloseOthers = actions.onCloseOthers {
            Button("Close Other Tabs", action: onCloseOthers)
                .shortcut(.closeOtherTabs, bindings: bindings)
        }
    }
}
