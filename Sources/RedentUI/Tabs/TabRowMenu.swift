import SwiftUI

/// The right-click menu shared by both tab strips.
struct TabRowMenu: View {
    let isPinned: Bool
    let actions: TabRowActions

    var body: some View {
        Button(isPinned ? "Unpin Tab" : "Pin Tab", action: actions.onTogglePin)
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
