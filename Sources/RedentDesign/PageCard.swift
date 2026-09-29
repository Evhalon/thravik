import SwiftUI

/// Frames web content as a card floating inside the chrome.
///
/// This is the single change that separates a browser window from an app that
/// happens to show a web page: the page has an edge, a shadow, and daylight
/// around it, so the chrome reads as holding it rather than abutting it.
private struct PageCard<Backdrop: View>: ViewModifier {
    let isInset: Bool
    let backdrop: Backdrop

    func body(content: Content) -> some View {
        content
            .overlay { cornerCover }
            .background { shadowPlate(cardShape) }
            .animation(.spring(duration: 0.3), value: isInset)
    }

    /// Paints the four spandrels so the card still reads round. `clipShape`
    /// would mask the WKWebView underneath; hardware video then goes black.
    ///
    /// Reuse every layer of the window backdrop, including its current Space
    /// wash. Reconstructing only part of it leaves dark notches in tinted glass.
    ///
    /// The card's shadow falls on that glass too, so the cover casts it again.
    /// Without it the corners read as a pale halo against the darkened slab.
    @ViewBuilder
    private var cornerCover: some View {
        if isInset {
            GeometryReader { proxy in
                if let window = proxy.bounds(of: WindowBackdrop.space) {
                    backdrop
                        .frame(width: window.width, height: window.height)
                        .offset(x: window.minX, y: window.minY)
                }
            }
            .overlay { castShadow }
            .mask { CardSpandrels(radius: Metric.pageRadius).fill(style: FillStyle(eoFill: true)) }
            .allowsHitTesting(false)
        }
    }

    /// The plate's shadow with the plate itself cut away, so the corner's soft
    /// edge blends page into glass rather than into a black rim.
    private var castShadow: some View {
        ZStack {
            shadowPlate(cardShape)
            cardShape.fill(.black).blendMode(.destinationOut)
        }
        .compositingGroup()
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: isInset ? Metric.pageRadius : 0, style: .continuous)
    }

    /// The shadow belongs to a shape *behind* the card, not to the card itself.
    /// Shadowing the content would put the live web view through an offscreen
    /// blur every time the page painted a frame — while scrolling, that is every
    /// frame — for a soft edge the user cannot see through opaque content anyway.
    @ViewBuilder
    private func shadowPlate(_ shape: RoundedRectangle) -> some View {
        if isInset {
            shape.fill(.black)
                .shadow(color: .black.opacity(0.50), radius: 26, y: 8)
                .shadow(color: .black.opacity(0.28), radius: 5, y: 1)
        }
    }
}

/// Everything in the rectangle outside its rounded card, filled even-odd.
private struct CardSpandrels: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addPath(RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: rect))
        return path
    }
}

public extension View {
    /// - Parameter isInset: `false` gives the page the whole pane, for focus mode.
    /// - Parameter backdrop: The complete backdrop drawn in `WindowBackdrop.space`.
    func pageCard<Backdrop: View>(
        isInset: Bool = true, @ViewBuilder backdrop: () -> Backdrop
    ) -> some View {
        modifier(PageCard(isInset: isInset, backdrop: backdrop()))
    }
}
