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
    @State private var addressFieldFrame: CGRect = .zero

    var body: some View {
        VStack(spacing: 0) {
            if showsChrome { chrome.zIndex(1) } else { windowButtonClearance }
            page
        }
        .coordinateSpace(.named(AddressFieldFrameKey.space))
        .onPreferenceChange(AddressFieldFrameKey.self) { addressFieldFrame = $0 }
        .overlay(alignment: .topLeading) {
            addressSuggestions
                .animation(.easeOut(duration: 0.12), value: model.suggestions.isOpen(for: .addressBar))
        }
    }

    /// Lives on the column, not the field: a list drawn inside the toolbar row
    /// is clipped under the page that sits below it.
    @ViewBuilder
    private var addressSuggestions: some View {
        if model.suggestions.isOpen(for: .addressBar), addressFieldFrame != .zero {
            SuggestionList(model: model)
                .frame(width: max(addressFieldFrame.width, 440), alignment: .leading)
                .offset(x: addressFieldFrame.minX, y: addressFieldFrame.maxY + 5)
        }
    }

    private var page: some View {
        ContentArea(model: model)
            .pageCard(isInset: !model.isFocusMode && !isShowingNewTab)
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
        if !model.isSidebarVisible {
            TitlebarDragRegion()
                .frame(height: Metric.windowButtonsHeight)
        }
    }

    private var showsChrome: Bool { !model.isFocusMode }

    private var isShowingNewTab: Bool { model.selectedTab?.url == nil }
}
