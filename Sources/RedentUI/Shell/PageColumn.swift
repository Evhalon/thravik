import RedentDesign
import SwiftUI

/// The chrome, and the page underneath it.
///
/// The toolbar is a row of its own: the page is laid out below it rather than
/// behind it. Floating it over the page cost nothing in height but covered the
/// top of every site — headers, banners and sticky navigation all sat under it.
///
/// Focus mode is the one state that keeps the row away.
struct PageColumn: View {
    @Bindable var model: BrowserModel
    let usesTopStrip: Bool

    var body: some View {
        VStack(spacing: 0) {
            if showsChrome { chrome } else { windowButtonClearance }
            page
        }
    }

    private var page: some View {
        ContentArea(model: model)
            .background(Palette.pageChrome)
            .pageCard(isInset: !model.isFocusMode)
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
    }

    /// The sliver the page owes the window buttons while focus mode has put
    /// the toolbar away.
    @ViewBuilder
    private var windowButtonClearance: some View {
        if !model.isSidebarVisible {
            Color.clear.frame(height: Metric.windowButtonsHeight)
        }
    }

    private var showsChrome: Bool { !model.isFocusMode }
}
