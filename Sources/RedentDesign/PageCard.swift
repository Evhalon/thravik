import SwiftUI

/// Frames web content as a card floating inside the chrome.
///
/// This is the single change that separates a browser window from an app that
/// happens to show a web page: the page has an edge, a shadow, and daylight
/// around it, so the chrome reads as holding it rather than abutting it.
private struct PageCard: ViewModifier {
    let isInset: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: isInset ? Metric.pageRadius : 0,
            style: .continuous
        )
        return content
            .clipShape(shape)
            .overlay {
                // A lit top edge over a dark bottom edge is what separates the
                // card from the chrome; a single flat stroke reads as a border.
                shape.strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(isInset ? 0.22 : 0), .white.opacity(isInset ? 0.04 : 0)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: Metric.hairWidth * 1.5
                )
            }
            .background { shadowPlate(shape) }
            .padding(isInset ? Metric.pageInset : 0)
            .animation(.spring(duration: 0.3), value: isInset)
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

public extension View {
    /// - Parameter isInset: `false` gives the page the whole pane, for focus mode.
    func pageCard(isInset: Bool = true) -> some View {
        modifier(PageCard(isInset: isInset))
    }
}
