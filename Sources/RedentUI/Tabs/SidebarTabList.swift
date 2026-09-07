import RedentDesign
import RedentKit
import SwiftUI

/// Vertical tab list with Dia-style related clusters.
struct SidebarTabList: View {
    @Bindable var model: BrowserModel
    var namespace: Namespace.ID
    @State private var collapsed = Set<UUID>()

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
        }
        .scrollIndicators(.never)
        .animation(.spring(duration: 0.3), value: model.tabs.selectedID)
        .onChange(of: model.tabs.selectedID) { _, id in expand(containing: id) }
    }

    private var outline: SidebarOutline {
        SidebarOutline(
            tabs: model.tabs.session.tabs,
            groups: model.tabs.session.groups,
            spaceID: model.tabs.session.selectedSpaceID
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
            actions: .init(onSelect: { selectHeader(cluster) }, onToggle: { toggle(cluster.id) })
        )
        if !folded {
            ForEach(cluster.memberIDs, id: \.self) { id in
                if let tab = tab(id) { row(tab, indent: Metric.gutter) }
            }
        }
    }

    private func row(_ tab: any BrowserTab, indent: CGFloat) -> some View {
        SidebarTabRow(
            tab: tab,
            isSelected: tab.id == model.tabs.selectedID,
            namespace: namespace,
            actions: actions(for: tab),
            indent: indent
        )
    }

    private func actions(for tab: any BrowserTab) -> SidebarTabActions {
        let grouped = tab.snapshot.groupID != nil || tab.snapshot.parentTabID != nil
        return SidebarTabActions(
            onSelect: { model.tabs.select(tab.id) },
            onClose: { model.tabs.close(tab.id) },
            onTogglePin: { model.tabs.togglePin(tab.id) },
            onUngroup: grouped ? { try? model.tabs.perform(.moveTabToGroup(tabID: tab.id, groupID: nil)) } : nil
        )
    }

    private func tab(_ id: UUID?) -> (any BrowserTab)? {
        guard let id else { return nil }
        return model.tabs.visibleTabs.first { $0.id == id }
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
