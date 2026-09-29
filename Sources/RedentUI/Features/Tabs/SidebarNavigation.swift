import RedentDesign
import SwiftUI

struct SidebarNavigation: View {
    @Bindable var model: BrowserModel

    var body: some View {
        VStack(spacing: Metric.tightGutter) {
            HStack(spacing: 1) {
                NavigationControls(model: model, showsTabToggle: false, showsReload: false)
                if model.showsFloatVideoControl { FloatVideoButton(model: model) }
                BrowserMenu(model: model, symbol: "ellipsis", showsPageActions: true)
            }
            .padding(.leading, Metric.windowButtonsWidth)
            .padding(.trailing, 4)
            .frame(height: Metric.toolbarHeight)
            .background { TitlebarDragRegion() }
            AddressField(model: model)
                .padding(.horizontal, Metric.gutter - 2)
        }
        .padding(.bottom, Metric.tightGutter)
    }
}
