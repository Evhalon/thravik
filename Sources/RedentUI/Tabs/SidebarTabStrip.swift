import RedentDesign
import RedentKit
import SwiftUI

/// The vertical rail: Space on top, tabs below, actions at the foot.
///
/// The address bar is not here any more — it lives on the window's first row,
/// alongside the window buttons. Transparent by design: the window's glass slab
/// shows through it.
struct SidebarTabStrip: View {
    @Bindable var model: BrowserModel
    @Namespace private var selection

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter + 2) {
            SpaceSwitcher(model: model)
            SidebarTabList(model: model, namespace: selection)
            SidebarFooter(model: model)
            SpacePageDots(
                spaces: model.tabs.session.spaces,
                selectedID: model.tabs.session.selectedSpaceID,
                onSelect: { model.execute(.focusSpace($0)) },
                onManage: { model.sheet = .spaces }
            )
        }
        .padding(.horizontal, Metric.gutter - 2)
        // Clears the window buttons, which now sit over the top of this rail.
        .padding(.top, Metric.toolbarHeight)
        .padding(.bottom, Metric.gutter)
        .background(alignment: .top) {
            SpaceWash(space: model.tabs.session.spaces.first { $0.id == model.tabs.session.selectedSpaceID })
        }
        .overlay { swipeOverlay }
        .animation(.easeInOut(duration: 0.22), value: model.tabs.session.selectedSpaceID)
    }

    private var swipeOverlay: some View {
        HorizontalSwipeCatcher(onStep: pageSpace)
            .allowsHitTesting(false)
    }

    private func pageSpace(_ step: Int) {
        let ids = model.tabs.session.spaces.map(\.id)
        guard let next = SpacePaging.neighbor(
            of: model.tabs.session.selectedSpaceID, in: ids, step: step
        ) else { return }
        model.execute(.focusSpace(next))
    }
}
