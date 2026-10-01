import RedentDesign
import RedentKit
import SwiftUI

/// A Space's pinned tabs as launcher tiles over its tab list.
///
/// A tab dragged over the tiles opens a gap where it would land, and the
/// tiles slide aside to make room. A tile dragged among the others moves the
/// same way.
struct PinnedTileGrid: View {
    let model: BrowserModel
    let spaceID: UUID?
    let pinDrop: PinDropTarget
    @State private var owner = UUID()
    @State private var frame = CGRect.zero
    @State private var drag: PinnedTileDrag?

    private static let dragSpace = "pinnedTiles"

    var body: some View {
        if pinnedIDs.isEmpty {
            PinDropZone(target: pinDrop)
        } else if !pinned.isEmpty {
            tiles
        }
    }

    private var tiles: some View {
        let pinned = pinned
        let cells = drag.map { PinnedCell.cells(pinned, moving: $0.tabID, to: $0.slot) }
            ?? PinnedCell.cells(pinned, gap: pinDrop.slot)
        return PinnedTileLayout {
            ForEach(cells) { cell in
                if let tab = cell.tab { tile(tab, count: pinned.count) } else { PinGap() }
            }
        }
        .coordinateSpace(.named(Self.dragSpace))
        .overlay(alignment: .topLeading) { liftedTile(in: pinned) }
        .animation(.spring(duration: 0.3, bounce: 0.1), value: cells.map(\.id))
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
            frame = $0
            pinDrop.track(owner, frame: $0, pins: pinned.count)
        }
        .onChange(of: pinned.count) { pinDrop.track(owner, frame: frame, pins: $1) }
        .onDisappear { pinDrop.forget(owner) }
    }

    /// A lifted tile keeps its cell, left empty, so its drag gesture lives on
    /// while the tile itself travels in `liftedTile`.
    private func tile(_ tab: any BrowserTab, count: Int) -> some View {
        let isLifted = drag?.tabID == tab.id
        return PinnedTile(tab: tab, isSelected: tab.id == model.tabs.selectedID, actions: actions(for: tab))
            .opacity(isLifted ? 0 : 1)
            .pinnedTileDragging(
                tab.id, drag: $drag, space: Self.dragSpace,
                slot: { slot(forTileAt: $0, count: count) },
                onDrop: { model.pin(tab.id, at: $0) }
            )
    }

    @ViewBuilder
    private func liftedTile(in pinned: [any BrowserTab]) -> some View {
        if let drag, let tab = pinned.first(where: { $0.id == drag.tabID }) {
            let geometry = PinnedTileGeometry(count: pinned.count, width: frame.width)
            PinnedTile(tab: tab, isSelected: tab.id == model.tabs.selectedID, actions: actions(for: tab))
                .frame(width: geometry.tileWidth, height: geometry.tileHeight)
                // The tile's own glass is see-through; lifted over its
                // neighbours it needs a solid body.
                .background(Palette.liftedChrome, in: .rect(cornerRadius: 11, style: .continuous))
                .scaleEffect(1.06)
                .shadow(color: .black.opacity(0.42), radius: 12, y: 4)
                .offset(x: drag.origin.x, y: drag.origin.y)
                .allowsHitTesting(false)
        }
    }

    /// The cell under the lifted tile's centre, so it moves once it mostly
    /// covers a neighbour rather than the moment its edge touches one.
    private func slot(forTileAt origin: CGPoint, count: Int) -> Int {
        let geometry = PinnedTileGeometry(count: count, width: frame.width)
        return geometry.slot(
            atX: origin.x + geometry.tileWidth / 2, y: origin.y + geometry.tileHeight / 2, count: count
        )
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
                onSelect: { model.selectTab(tab.id) },
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
