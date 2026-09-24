import RedentDesign
import RedentKit
import SwiftUI

/// Vertical tab list with Dia-style related clusters, for one Space: the
/// pager also draws the neighbouring Spaces' lists as they slide in.
struct SidebarTabList: View {
    @Bindable var model: BrowserModel
    var namespace: Namespace.ID
    let spaceID: UUID?

    /// Named so a row's frame and the pointer are measured against the same
    /// origin even after the list scrolls.
    nonisolated static let dragSpace = "sidebarTabs"

    @State private var collapsed = Set<UUID>()
    @State private var drag = TabDragCoordinator(axis: .vertical)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(outline.nodes) { node in
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
        }
        .scrollIndicators(.never)
        .animation(.spring(duration: 0.3), value: model.tabs.selectedID)
        .animation(.spring(duration: 0.3), value: model.split.tabIDs)
        .onChange(of: model.tabs.selectedID) { _, id in expand(containing: id) }
    }

    private var outline: SidebarOutline {
        SidebarOutline(
            tabs: model.tabs.session.tabs,
            groups: model.tabs.session.groups,
            spaceID: spaceID
        )
    }

    @ViewBuilder
    private func clusterBlock(_ cluster: SidebarNode.Cluster) -> some View {
        let folded = collapsed.contains(cluster.id)
        SidebarGroupHeader(
            cluster: cluster,
            iconTab: tab(cluster.headerTabID ?? cluster.memberIDs.first),
            isSelected: cluster.headerTabID == model.tabs.selectedID,
            isCollapsed: folded,
            actions: .init(
                onSelect: { selectHeader(cluster) },
                onToggle: { toggle(cluster.id) },
                onClose: { model.tabs.closeTabs(Set(clusterTabIDs(cluster))) }
            )
        )
        // A header the drag does not know about is a dead band the pointer has
        // to cross blind, so it joins the geometry like any other row.
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.dragSpace)) } action: {
            drag.track(cluster.id, drawing: headerTabs(cluster, folded: folded), frame: $0)
        }
        .onDisappear { drag.forget(cluster.id) }
        if !folded {
            ForEach(cluster.memberIDs, id: \.self) { id in
                if let tab = tab(id) { row(tab, indent: Metric.gutter) }
            }
        }
    }

    private func headerTabs(_ cluster: SidebarNode.Cluster, folded: Bool) -> [UUID] {
        let header = cluster.headerTabID.map { [$0] } ?? []
        return folded ? header + cluster.memberIDs : header
    }

    private func clusterTabIDs(_ cluster: SidebarNode.Cluster) -> [UUID] {
        (cluster.headerTabID.map { [$0] } ?? []) + cluster.memberIDs
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
            onSelect: { model.tabs.select(tab.id) },
            onClose: { model.tabs.close(tab.id) },
            onTogglePin: { model.tabs.togglePin(tab.id) },
            onDuplicate: tab.url == nil ? nil : { _ = model.tabs.duplicateTab(tab.id) },
            onSplit: model.canSplit(with: tab.id) ? { model.splitWith(tab.id) } : nil,
            onUnsplit: model.isInSplit(tab.id) ? { model.removeFromSplit(tab.id) } : nil,
            onCloseOthers: canCloseOthers(than: tab) ? { model.tabs.closeOthers(than: tab.id) } : nil,
            onUngroup: grouped ? { try? model.tabs.perform(.moveTabToGroup(tabID: tab.id, groupID: nil)) } : nil,
            onReorder: { model.commitTabDrag(tab.id, order: $0) }
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

    private func selectHeader(_ cluster: SidebarNode.Cluster) {
        if let id = cluster.headerTabID { model.tabs.select(id) }
        else { toggle(cluster.id) }
    }

    private func toggle(_ id: UUID) {
        if collapsed.contains(id) { collapsed.remove(id) } else { collapsed.insert(id) }
    }

    private func expand(containing id: UUID?) {
        guard let id, let tab = tab(id) else { return }
        if let groupID = tab.snapshot.groupID { collapsed.remove(groupID) }
        if let parent = tab.snapshot.parentTabID { collapsed.remove(parent) }
    }
}
