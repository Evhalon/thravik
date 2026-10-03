import RedentDesign
import RedentKit
import SwiftUI

/// A cluster's header row in `SidebarTabList`: naming, folding, drag geometry,
/// and the archive actions Tidy Tabs adds to its groups.
struct SidebarClusterHeader: View {
    @Bindable var model: BrowserModel
    let cluster: SidebarNode.Cluster
    @Binding var collapsed: Set<UUID>
    @Bindable var drag: TabDragCoordinator
    let tab: (UUID?) -> (any BrowserTab)?

    var body: some View {
        let naming = model.settings.namesGroupsOnDevice
        let folded = collapsed.contains(cluster.id)
        SidebarGroupHeader(
            title: model.groupNames.displayName(for: cluster, isEnabled: naming),
            siteName: cluster.name,
            iconTab: tab(cluster.memberIDs.first),
            isCollapsed: folded,
            actions: .init(
                onToggle: { collapsed.formSymmetricDifference([cluster.id]) },
                onClose: closeCluster,
                onRestore: isArchivedCluster ? { model.restoreArchivedGroup(cluster.id) } : nil
            )
        )
        .task(id: naming ? Set(cluster.memberIDs) : []) {
            await model.groupNames.resolve(cluster, isEnabled: naming) { pages }
        }
        // A header the drag does not know about is a dead band the pointer has
        // to cross blind, so it joins the geometry like any other row.
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(SidebarTabList.dragSpace)) } action: {
            drag.track(.header(cluster.id), drawing: folded ? cluster.memberIDs : [], frame: $0)
        }
        .onDisappear { drag.forget(.header(cluster.id)) }
        .offset(drag.offset(for: .header(cluster.id)))
    }

    private var pages: [TabGroupPage] {
        cluster.memberIDs.compactMap { tab($0) }.map {
            TabGroupPage(title: $0.snapshot.displayTitle, host: $0.origin?.displayHost ?? "")
        }
    }

    /// Only a saved group can be restored; a site cluster's name is a page title.
    private var isArchivedCluster: Bool {
        guard let group = model.tabs.session.groups.first(where: { $0.id == cluster.id }) else { return false }
        return TidyTabsArchive.isArchivedGroupName(group.name)
    }

    private func closeCluster() {
        if model.tabs.session.groups.contains(where: { $0.id == cluster.id }) {
            model.tabs.closeGroup(cluster.id)
        } else {
            model.tabs.closeTabs(Set(cluster.memberIDs))
        }
    }
}
