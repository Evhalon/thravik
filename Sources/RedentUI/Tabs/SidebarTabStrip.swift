import RedentDesign
import RedentKit
import SwiftUI

/// The vertical rail: address bar on top, tabs below, actions at the foot.
/// Transparent by design — the window's glass slab shows through it.
struct SidebarTabStrip: View {
    @Bindable var model: BrowserModel
    @Namespace private var selection

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter + 2) {
            SpaceSwitcher(model: model)
            NavigationControls(model: model)
            AddressField(model: model)
                // Its dropdown overhangs the tab list below and the page to the
                // right; without an explicit order both paint over it.
                .zIndex(2)
            SidebarTabList(model: model, namespace: selection)
                .zIndex(0)
            SidebarFooter(model: model)
            SpacePageDots(
                spaces: model.tabs.session.spaces,
                selectedID: model.tabs.session.selectedSpaceID,
                onSelect: { model.execute(.focusSpace($0)) },
                onManage: { model.sheet = .spaces }
            )
        }
        .padding(.horizontal, Metric.gutter - 2)
        .padding(.top, Metric.tightGutter)
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
