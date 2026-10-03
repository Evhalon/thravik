import RedentKit
import SwiftUI

/// Shared Set / Remove items for tab and pinned-tile context menus.
struct TabEmojiMenuItems: View {
    let tab: any BrowserTab
    let onPick: () -> Void

    var body: some View {
        Button("Set Emoji Icon…", action: onPick)
        if tab.snapshot.customEmoji != nil {
            Button("Remove Emoji Icon") { tab.setCustomEmoji(nil) }
        }
    }
}
