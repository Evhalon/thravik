import RedentDesign
import SwiftUI

/// The chrome, and the page underneath it.
///
/// The toolbar owns a row of its own at the top of the column: it is always on
/// screen and the page begins below it. Overlaying it on the page cost nothing
/// in height but covered the top of every site — headers, banners and sticky
/// navigation bars sat under a panel that came and went with the pointer.
///
/// Focus mode is the one case that still gives the row back to the page.
struct PageColumn: View {
    @Bindable var model: BrowserModel
    let usesTopStrip: Bool

    var body: some View {
        VStack(spacing: 0) {
            chrome
            page
        }
        .animation(.spring(duration: 0.28), value: model.isFocusMode)
    }

    private var page: some View {
        ContentArea(model: model)
            .background(Palette.pageChrome)
            .pageCard(isInset: !model.isFocusMode)
    }

    /// Without the rail there is nothing else holding the window buttons, so the
    /// row starts clear of them. With it, they sit over the rail and the row
    /// runs to the seam.
    @ViewBuilder
    private var chrome: some View {
        if !model.isFocusMode {
            VStack(spacing: 0) {
                if usesTopStrip { TopTabStrip(model: model) }
                ChromeBar(model: model)
            }
            .padding(.leading, model.isSidebarVisible ? 0 : Metric.windowButtonsWidth)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
