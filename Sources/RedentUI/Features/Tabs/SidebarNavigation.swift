import RedentDesign
import SwiftUI

struct SidebarNavigation: View {
    @Bindable var model: BrowserModel
    @Environment(\.extensionToolbar) private var extensionToolbar

    var body: some View {
        VStack(spacing: Metric.tightGutter) {
            HStack(spacing: 1) {
                NavigationControls(model: model, showsTabToggle: false, showsReload: false)
                if model.showsFloatVideoControl { FloatVideoButton(model: model) }
                if let extensionToolbar { extensionToolbar }
                DownloadsButton(model: model)
                BrowserMenu(model: model, symbol: "ellipsis", showsPageActions: true)
            }
            .padding(.leading, Metric.windowButtonsWidth)
            .padding(.trailing, 4)
            .frame(height: Metric.toolbarHeight)
            .background { TitlebarDragRegion() }
            addressRow
                .padding(.horizontal, Metric.gutter - 2)
        }
        .padding(.bottom, Metric.tightGutter)
    }

    /// Without the toolbar this is the only place a private window can say so,
    /// beside the address just as `ChromeBar` does.
    private var addressRow: some View {
        HStack(spacing: Metric.tightGutter) {
            AddressField(model: model)
                .zIndex(1)
            if model.isPrivate {
                ChromeBadge("PRIVATE", tint: Palette.accent)
                    .fixedSize()
                    .help("Private window")
            }
        }
    }
}
