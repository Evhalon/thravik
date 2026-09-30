import RedentDesign
import RedentKit
import SwiftUI

/// The vertical rail: Spaces paged side by side on top, actions at the foot.
///
/// Navigation can live above the Spaces, leaving the page's top edge clear.
struct SidebarTabStrip: View {
    @Bindable var model: BrowserModel
    @Namespace private var selection

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter + 2) {
            if model.usesSidebarNavigation { SidebarNavigation(model: model) }
            SpacePager(
                spaces: model.tabs.session.spaces,
                selectedID: model.tabs.session.selectedSpaceID,
                onSelect: { model.execute(.focusSpace($0)) },
                page: spacePage
            )
            VStack(alignment: .leading, spacing: Metric.tightGutter + 2) {
                SidebarFooter(model: model)
                SpacePageDots(
                    spaces: model.tabs.session.spaces,
                    selectedID: model.tabs.session.selectedSpaceID,
                    onSelect: { model.execute(.focusSpace($0)) },
                    onManage: { model.sheet = .spaces },
                    updates: model.updates
                )
            }
            .padding(.horizontal, Metric.gutter - 2)
        }
        .padding(.bottom, Metric.gutter)
        .overlay(alignment: .top) {
            TitlebarDragRegion()
                .frame(height: Metric.toolbarHeight)
                .allowsHitTesting(!model.usesSidebarNavigation)
        }
        .animation(.spring(duration: 0.34, bounce: 0.08), value: model.tabs.session.selectedSpaceID)
    }

    private func spacePage(_ space: BrowserSpace) -> some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter + 2) {
            PinnedTileGrid(model: model, spaceID: space.id)
            SpaceSwitcher(model: model, current: space)
            SidebarTabList(model: model, namespace: selection, spaceID: space.id)
        }
        .padding(.horizontal, Metric.gutter - 2)
        // Clears the window buttons, which now sit over the top of this rail.
        .padding(.top, model.usesSidebarNavigation ? 0 : Metric.toolbarHeight)
    }
}
