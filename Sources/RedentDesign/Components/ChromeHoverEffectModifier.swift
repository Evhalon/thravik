import SwiftUI

/// The fill that appears under a hovered or selected chrome control.
///
/// Two layers rather than one flat fill: a soft body plus a brighter top edge,
/// so a selected tab reads as raised off the glass instead of painted onto it.
private struct ChromeHoverEffect: ViewModifier {
    let isActive: Bool
    let radius: CGFloat

    func body(content: Content) -> some View {
        content.background {
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            ZStack {
                shape.fill(Palette.chromeFill)
                shape.strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.22), .white.opacity(0.04)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: Metric.hairWidth
                )
            }
            .opacity(isActive ? 1 : 0)
            .animation(.easeOut(duration: 0.14), value: isActive)
        }
    }
}

public extension View {
    func chromeHoverEffect(isActive: Bool, radius: CGFloat = Metric.mediumRadius) -> some View {
        modifier(ChromeHoverEffect(isActive: isActive, radius: radius))
    }
}
