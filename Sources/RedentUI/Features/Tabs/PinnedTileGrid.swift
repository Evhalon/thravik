import RedentKit
import SwiftUI

/// A Space's pinned tabs as launcher tiles over its tab list.
struct PinnedTileGrid: View {
    let model: BrowserModel
    let spaceID: UUID?
    let pinDrop: PinDropTarget

    var body: some View {
        if pinnedIDs.isEmpty {
            PinDropZone(target: pinDrop)
        } else if !pinned.isEmpty {
            PinnedTileLayout {
                ForEach(pinned, id: \.id) { tab in
                    PinnedTile(tab: tab, isSelected: tab.id == model.tabs.selectedID, actions: actions(for: tab))
                }
            }
            .animation(.spring(duration: 0.3, bounce: 0.1), value: pinned.map(\.id))
        }
    }

    /// A pin a split is showing is drawn as the split's row instead.
    private var pinned: [any BrowserTab] {
        let ids = pinnedIDs.filter { !model.isInSplit($0) }
        return ids.compactMap { id in model.tabs.tabs.first { $0.id == id } }
    }

    private var pinnedIDs: [UUID] {
        SidebarOutline(
            tabs: model.tabs.session.tabs, groups: model.tabs.session.groups, spaceID: spaceID
        ).pinnedIDs
    }

    private func actions(for tab: any BrowserTab) -> PinnedTileActions {
        let snapshot = tab.snapshot
        let canRepin = tab.url != nil && tab.url != snapshot.pinnedURL
        return PinnedTileActions(
            row: TabRowActions(
                onSelect: { model.tabs.select(tab.id) },
                onClose: { model.tabs.close(tab.id) },
                onTogglePin: { model.tabs.togglePin(tab.id) },
                onDuplicate: tab.url == nil ? nil : { _ = model.tabs.duplicateTab(tab.id) },
                onSplit: model.canSplit(with: tab.id) ? { model.splitWith(tab.id) } : nil
            ),
            onReturn: snapshot.pinnedPageElsewhere == nil ? nil : { model.returnToPinnedPage(tab.id) },
            onPinCurrentPage: canRepin ? { model.pinCurrentPage(tab.id) } : nil,
            onCopyLink: tab.url.map { url in { model.copyLink(url) } },
            onRename: { model.renameTab(tab.id, to: $0) },
            moveTargets: model.spaces(besides: tab.id),
            onMove: { model.execute(.moveTab(tabID: tab.id, spaceID: $0)) }
        )
    }
}
