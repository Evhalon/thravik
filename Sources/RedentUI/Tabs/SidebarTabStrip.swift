import RedentDesign
import RedentKit
import SwiftUI

/// The vertical rail: Spaces paged side by side on top, actions at the foot.
///
/// The address bar is not here any more — it lives on the window's first row,
/// alongside the window buttons. Transparent by design: the window's glass slab
/// shows through it.
struct SidebarTabStrip: View {
    @Bindable var model: BrowserModel
    @Namespace private var selection

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter + 2) {
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
                    onManage: { model.sheet = .spaces }
                )
            }
            .padding(.horizontal, Metric.gutter - 2)
        }
        .padding(.bottom, Metric.gutter)
        .overlay(alignment: .top) {
            TitlebarDragRegion()
                .frame(height: Metric.toolbarHeight)
        }
        .animation(.spring(duration: 0.34, bounce: 0.08), value: model.tabs.session.selectedSpaceID)
    }

    /// Each Space carries its own wash, so its colour slides in with it.
    private func spacePage(_ space: BrowserSpace) -> some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter + 2) {
            SpaceSwitcher(model: model, current: space)
            SidebarTabList(model: model, namespace: selection, spaceID: space.id)
        }
        .padding(.horizontal, Metric.gutter - 2)
        // Clears the window buttons, which now sit over the top of this rail.
        .padding(.top, Metric.toolbarHeight)
        .background(alignment: .top) { SpaceWash(space: space) }
    }
}
