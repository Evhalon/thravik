import RedentDesign
import RedentKit
import SwiftUI

/// Wears the current Space's wash and grain as one band over the whole
/// panel, so it reads as part of the workspace rather than a dropdown.
struct FloatingPanelSurface: View {
    let space: BrowserSpace?
    @Environment(\.ambientTint) private var tint
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        ZStack {
            VisualEffectBackdrop(.floating)
            Palette.dropdownBase.opacity(0.76)
            AmbientWash(tint: tint, intensity: 0.10)
            spaceWash
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

    @ViewBuilder private var spaceWash: some View {
        if let space {
            let token = SpaceIdentity.look(id: space.id, icon: space.icon, colorToken: space.colorToken).colorToken
            SpaceWashFill(tint: SpaceTint(token: token), color: SpaceTintColor.color(token), strength: 1.4)
        }
    }
}
