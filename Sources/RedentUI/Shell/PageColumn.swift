import RedentDesign
import SwiftUI

/// The chrome, and the page underneath it.
///
/// The toolbar is away until the pointer reaches the top band, and then it
/// arrives as a row of its own: the page is laid out below it rather than
/// behind it. Floating it over the page cost nothing in height but covered the
/// top of every site — headers, banners and sticky navigation all sat under it.
///
/// Focus mode is the one state that keeps the row away for good.
struct PageColumn: View {
    @Bindable var model: BrowserModel
    let usesTopStrip: Bool

    @State private var isProbeHovered = false
    @State private var isChromeHovered = false

    var body: some View {
        VStack(spacing: 0) {
            if showsChrome { chrome } else { windowButtonClearance }
            page
        }
        .overlay(alignment: .top) { probe }
    }

    private var page: some View {
        ContentArea(model: model)
            .background(Palette.pageChrome)
            .pageCard(isInset: !model.isFocusMode)
    }

    /// Deep enough to cover the row it summons, so the pointer never crosses a
    /// dead band on its way down to the address field.
    private var probe: some View {
        HoverProbe { isProbeHovered = $0 }
            .frame(height: Metric.chromeProbeHeight)
    }

    /// Deliberately unanimated. The row's height is the page's height, and a
    /// live web view relaid out on every frame of a slide is both expensive and
    /// visibly torn — it arrives in one step instead.
    ///
    /// Without the rail there is nothing else holding the window buttons, so the
    /// row starts clear of them. With it, they sit over the rail and the row
    /// runs to the seam.
    private var chrome: some View {
        VStack(spacing: 0) {
            if usesTopStrip { TopTabStrip(model: model) }
            ChromeBar(model: model)
        }
        .padding(.leading, model.isSidebarVisible ? 0 : Metric.windowButtonsWidth)
        .onHover { isChromeHovered = $0 }
    }

    /// The sliver the page owes the window buttons while the toolbar is away.
    @ViewBuilder
    private var windowButtonClearance: some View {
        if !model.isSidebarVisible {
            Color.clear.frame(height: Metric.windowButtonsHeight)
        }
    }

    private var showsChrome: Bool {
        !model.isFocusMode && isRevealed
    }

    /// Anything the user is in the middle of pins the chrome open: an address
    /// they are typing must not vanish because the pointer drifted onto the page.
    private var isRevealed: Bool {
        isProbeHovered
            || isChromeHovered
            || model.address.isEditing
            || model.suggestions.isOpen(for: .addressBar)
    }
}
