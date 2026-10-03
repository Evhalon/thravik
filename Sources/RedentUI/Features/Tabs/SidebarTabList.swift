import RedentDesign
import RedentKit
import SwiftUI

/// Vertical tab list with Dia-style related clusters, for one Space: the
/// pager also draws the neighbouring Spaces' lists as they slide in. Pinned
/// tabs are `PinnedTileGrid`'s, above it.
struct SidebarTabList: View {
    @Bindable var model: BrowserModel
    var namespace: Namespace.ID
    let spaceID: UUID?

    /// Named so a row's frame and the pointer are measured against the same
    /// origin even after the list scrolls.
    nonisolated static let dragSpace = "sidebarTabs"

    @State private var collapsed = Set<UUID>()
    @State private var drag = TabDragCoordinator(axis: .vertical)
    @State private var foldedArchiveIDs = Set<UUID>()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(outline.listNodes(keeping: model.split.tabIDs)) { node in
                    switch node {
                    case .tab(let id):
                        if let tab = tab(id) { row(tab, indent: 0) }
                    case .cluster(let cluster):
                        clusterBlock(cluster)
                    }
                }
            }
            .padding(.vertical, 2)
            .coordinateSpace(.named(Self.dragSpace))
            .background(RigidScrollEdges())
        }
        .scrollIndicators(.never)
        .clipped()
        .onScrollGeometryChange(for: CGRect.self, of: \.visibleRect) { _, rect in drag.viewport = rect }
        .animation(.spring(duration: 0.3), value: model.tabs.selectedID)
        .animation(.spring(duration: 0.3), value: model.split.tabIDs)
        .onChange(of: model.tabs.selectedID) { _, id in expand(containing: id) }
        .onChange(of: archivedGroupIDs, initial: true) { _, ids in foldNewArchives(ids) }
    }

    @ViewBuilder
    private func clusterBlock(_ cluster: SidebarNode.Cluster) -> some View {
        SidebarClusterHeader(model: model, cluster: cluster, collapsed: $collapsed, drag: drag, tab: tab)
        if !collapsed.contains(cluster.id) {
            ForEach(cluster.memberIDs, id: \.self) { id in
                if let tab = tab(id) { row(tab, indent: Metric.gutter) }
            }
        }
    }

    private var archivedGroupIDs: Set<UUID> {
        Set(model.tabs.session.groups.filter { TidyTabsArchive.isArchivedGroupName($0.name) }.map(\.id))
    }

    /// Folds an archive once, when it first appears; one the user opened stays open.
    private func foldNewArchives(_ ids: Set<UUID>) {
        collapsed.formUnion(ids.subtracting(foldedArchiveIDs))
        foldedArchiveIDs = ids
    }

    private var outline: SidebarOutline {
        SidebarOutline(
            tabs: model.tabs.session.tabs,
            groups: model.tabs.session.groups,
            spaceID: spaceID
        )
    }

    /// A split is one entry, drawn where its first tab sits; its other tabs
    /// have no row of their own while it lasts.
    @ViewBuilder
    private func row(_ tab: any BrowserTab, indent: CGFloat) -> some View {
        if model.isInSplit(tab.id) {
            if tab.id == model.split.tabIDs.first {
                SplitTabRow(model: model, namespace: namespace, indent: indent)
            }
        } else {
            tabRow(tab, indent: indent)
        }
    }

    private func tabRow(_ tab: any BrowserTab, indent: CGFloat) -> some View {
        SidebarTabRow(
            tab: tab,
            isSelected: tab.id == model.tabs.selectedID,
            namespace: namespace,
            actions: actions(for: tab),
            drag: drag,
            indent: indent
        )
    }

    private func actions(for tab: any BrowserTab) -> TabRowActions {
        let grouped = tab.snapshot.groupID != nil || tab.snapshot.parentTabID != nil
        return TabRowActions(
            onSelect: { model.selectTab(tab.id) },
            onClose: { model.tabs.close(tab.id) },
            onTogglePin: { model.tabs.togglePin(tab.id) },
            onDuplicate: tab.url == nil ? nil : { _ = model.tabs.duplicateTab(tab.id) },
            onSplit: model.canSplit(with: tab.id) ? { model.splitWith(tab.id) } : nil,
            onUnsplit: model.isInSplit(tab.id) ? { model.removeFromSplit(tab.id) } : nil,
            onCloseOthers: canCloseOthers(than: tab) ? { model.tabs.closeOthers(than: tab.id) } : nil,
            onUngroup: grouped ? { try? model.tabs.perform(.moveTabToGroup(tabID: tab.id, groupID: nil)) } : nil,
            onReorder: { model.commitTabDrag(tab.id, order: $0) },
            onPin: { model.pin(tab.id, at: $0) },
            onDetach: model.canDetach(tab.id) ? { model.tearOff(tab.id, into: $0) } : nil
        )
    }

    private func canCloseOthers(than tab: any BrowserTab) -> Bool {
        // Closing others acts on the selected Space, never on a neighbour sliding by.
        spaceID == model.tabs.session.selectedSpaceID
            && model.tabs.visibleTabs.contains { $0.id != tab.id && !$0.isPinned }
    }

    private func tab(_ id: UUID?) -> (any BrowserTab)? {
        guard let id else { return nil }
        return model.tabs.tabs.first { $0.id == id && $0.snapshot.spaceID == spaceID }
    }

    /// Selecting a tab hidden in a folded group opens the group, so the
    /// selection is never out of sight.
    private func expand(containing id: UUID?) {
        guard let id else { return }
        for case .cluster(let cluster) in outline.nodes where cluster.memberIDs.contains(id) {
            collapsed.remove(cluster.id)
        }
    }
}
