import SwiftUI

/// Frames web content as a card floating inside the chrome.
///
/// This is the single change that separates a browser window from an app that
/// happens to show a web page: the page has an edge, a shadow, and daylight
/// around it, so the chrome reads as holding it rather than abutting it.
private struct PageCard: ViewModifier {
    let isInset: Bool
    @Environment(\.ambientTint) private var tint

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: isInset ? Metric.pageRadius : 0,
            style: .continuous
        )
        return content
            .overlay { cornerCover }
            .background { shadowPlate(shape) }
            .animation(.spring(duration: 0.3), value: isInset)
    }

    /// Paints the four spandrels so the card still reads round. `clipShape`
    /// would mask the WKWebView underneath; hardware video then goes black.
    ///
    /// They are painted with the window's own backdrop, laid at the same window
    /// position, so the corner shows exactly the glass behind it. Any flat fill
    /// stood out as a square notch against the tinted, wallpaper-lit slab.
    @ViewBuilder
    private var cornerCover: some View {
        if isInset {
            GeometryReader { proxy in
                if let window = proxy.bounds(of: WindowBackdrop.space) {
                    WindowBackdrop(tint: tint).equatable()
                        .frame(width: window.width, height: window.height)
                        .offset(x: window.minX, y: window.minY)
                } else {
                    Palette.canvas
                }
            }
            .mask { CardSpandrels(radius: Metric.pageRadius).fill(style: FillStyle(eoFill: true)) }
            .allowsHitTesting(false)
        }
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
    func pageCard(isInset: Bool = true) -> some View {
        modifier(PageCard(isInset: isInset))
    }
}
