import RedentDesign
import SwiftUI

/// The page, and the chrome that floats over the top of it.
///
/// The toolbar owns no height: the body runs flush to the top of the card, and
/// the toolbar arrives as a floating panel over it when the pointer reaches the
/// top band. Overlaid rather than inserted, so revealing it never reflows the
/// page underneath — a web view relaid out on every hover is both expensive and
/// visibly jumpy.
struct PageColumn: View {
    @Bindable var model: BrowserModel
    let usesTopStrip: Bool

    @State private var isProbeHovered = false
    @State private var isChromeHovered = false

    var body: some View {
        ZStack(alignment: .top) {
            page
            probe
            chrome
        }
        .background(Palette.pageChrome)
        .pageCard(isInset: !model.isFocusMode)
        .animation(.easeOut(duration: 0.16), value: isRevealed)
    }

    /// Without the rail there is nothing left to hold the window buttons, so the
    /// page gives up that much of its top edge. With it, the page is flush.
    @ViewBuilder
    private var page: some View {
        if model.isSidebarVisible {
            ContentArea(model: model)
        } else {
            VStack(spacing: 0) {
                Color.clear.frame(height: Metric.windowButtonsHeight)
                ContentArea(model: model)
            }
        }
    }

    /// Deep enough to cover the panel it summons, so the pointer never crosses a
    /// dead band on its way down to the address field.
    private var probe: some View {
        HoverProbe { isProbeHovered = $0 }
            .frame(height: Metric.chromeProbeHeight)
    }

    @ViewBuilder
    private var chrome: some View {
        if !model.isFocusMode {
            VStack(spacing: 0) {
                if usesTopStrip { TopTabStrip(model: model) }
                ChromeBar(model: model)
            }
            .floatingGlass(in: RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
            .frame(maxWidth: 780)
            .padding(.top, Metric.tightGutter)
            .opacity(isRevealed ? 1 : 0)
            .offset(y: isRevealed ? 0 : -Metric.gutter)
            .onHover { isChromeHovered = $0 }
            .allowsHitTesting(isRevealed)
        }
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
