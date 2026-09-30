import RedentDesign
import SwiftUI

struct FloatingNewTabSurface: View {
    @Environment(\.ambientTint) private var tint
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        ZStack {
            VisualEffectBackdrop(.floating)
            Palette.dropdownBase.opacity(0.76)
            AmbientWash(tint: tint, intensity: 0.10)
            LinearGradient(
                colors: [.white.opacity(scheme == .dark ? 0.10 : 0.48), .clear,
                         .black.opacity(scheme == .dark ? 0.12 : 0.03)],
                startPoint: .top, endPoint: .bottom
            )
            NoiseOverlay(opacity: 0.006)
        }
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(scheme == .dark ? 0.30 : 0.86),
                             Palette.hairline, .black.opacity(0.10)],
                    startPoint: .top, endPoint: .bottom
                ), lineWidth: Metric.hairWidth
            )
        }
    }
}
