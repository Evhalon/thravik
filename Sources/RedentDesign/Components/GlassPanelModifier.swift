import SwiftUI

public extension View {
    /// A glass panel with a rounded rectangle edge.
    ///
    /// Kept as the general-purpose entry point; it composes the same five-layer
    /// surface as everything else so panels never drift out of family.
    func glassPanel(radius: CGFloat = Metric.cornerRadius, tint: Color? = nil) -> some View {
        glassSurface(in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .environment(\.ambientTint, tint)
    }
}
