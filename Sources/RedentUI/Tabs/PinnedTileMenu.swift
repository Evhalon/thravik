import RedentKit
import SwiftUI

/// The right-click menu of a pinned tile. It changes with where the tab is:
/// away from its pinned page it offers the way back, and to keep the new page.
struct PinnedTileMenu: View {
    let tab: any BrowserTab
    let actions: PinnedTileActions
    let onRename: () -> Void

    var body: some View {
        Button("Unpin", action: actions.row.onTogglePin)
        if let onReturn = actions.onReturn {
            Button("Return to \(pinnedPageName)", action: onReturn)
        }
        Divider()
        viewing
        moving
        Divider()
        Button("Rename…", action: onRename)
        Menu("Edit Pinned Page") { pinnedPage }
        if tab.isPlayingAudio || tab.isMuted {
            Button(tab.isMuted ? "Unmute Tab" : "Mute Tab") { tab.setMuted(!tab.isMuted) }
        }
        Divider()
        Button("Close", action: actions.row.onClose)
            .keyboardShortcut("w")
    }

    @ViewBuilder
    private var viewing: some View {
        if let onSplit = actions.row.onSplit {
            Button("Open as Split", action: onSplit)
        }
        if let onUnsplit = actions.row.onUnsplit {
            Button("Remove from Split View", action: onUnsplit)
        }
        if let onDuplicate = actions.row.onDuplicate {
            Button("Duplicate", action: onDuplicate)
        }
    }

    @ViewBuilder
    private var moving: some View {
        if !actions.moveTargets.isEmpty {
            Menu("Move to Space") {
                ForEach(actions.moveTargets) { space in
                    Button(space.name) { actions.onMove(space.id) }
                }
            }
        }
        if let onCopyLink = actions.onCopyLink {
            Button("Copy Link", action: onCopyLink)
        }
    }

    @ViewBuilder
    private var pinnedPage: some View {
        if let pinnedURL = tab.snapshot.pinnedURL {
            Text(pinnedURL.host() ?? pinnedURL.absoluteString)
        }
        Button("Replace with Current Page", action: actions.onPinCurrentPage ?? {})
            .disabled(actions.onPinCurrentPage == nil)
    }

    private var pinnedPageName: String {
        tab.snapshot.pinnedPageElsewhere.flatMap { Origin(url: $0)?.displayHost } ?? "Pinned Page"
    }
}
