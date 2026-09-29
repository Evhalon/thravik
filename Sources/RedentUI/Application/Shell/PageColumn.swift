import RedentDesign
import SwiftUI

/// The chrome, and the page underneath it.
///
/// Visible navigation reserves a row; edge-revealed navigation overlays the
/// page temporarily without changing a site's layout or scroll position.
struct PageColumn<Backdrop: View>: View {
    @Bindable var model: BrowserModel
    let usesTopStrip: Bool
    let backdrop: Backdrop

    var body: some View {
        VStack(spacing: 0) {
            if model.showsNavigationBar { chrome.zIndex(1) } else { windowButtonClearance }
            page
        }
    }

    private var page: some View {
        ContentArea(model: model)
            .pageCard(isInset: !model.isFocusMode && !model.usesEdgeReveal && !isShowingNewTab) { backdrop }
    }

    /// Without the rail there is nothing else holding the window buttons, so the
    /// row starts clear of them. With it, they sit over the rail and the row
    /// runs to the seam.
    private var chrome: some View {
        VStack(spacing: 0) {
            if usesTopStrip { TopTabStrip(model: model) }
            ChromeBar(model: model)
        }
        .padding(.leading, model.isSidebarVisible ? 0 : Metric.windowButtonsWidth)
        .background { TitlebarDragRegion() }
    }

    /// The sliver the page owes the window buttons while focus mode has put
    /// the toolbar away.
    @ViewBuilder
    private var windowButtonClearance: some View {
        if !model.isSidebarVisible && !model.usesEdgeReveal {
            WindowControlsClearance(model: model)
        }
    }

    private var isShowingNewTab: Bool { model.selectedTab?.url == nil }
}
