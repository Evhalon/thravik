import RedentDesign
import RedentKit
import SwiftUI

/// Soft Space color pooling across the top of the window, like Arc's profile
/// glow. It spans the rail and the toolbar row alike, so the two read as one
/// surface instead of meeting at a seam.
struct SpaceWash: View {
    let space: BrowserSpace?

    var body: some View {
        if let space {
            let token = look(space).colorToken
            SpaceWashFill(tint: SpaceTint(token: token), color: SpaceTintColor.color(token))
                .frame(height: 170)
                .allowsHitTesting(false)
        }
    }

    private func look(_ space: BrowserSpace) -> SpaceIdentity.Look {
        SpaceIdentity.look(id: space.id, icon: space.icon, colorToken: space.colorToken)
    }
}

/// The wash itself, shared by the window and the composer's style picker.
struct SpaceWashFill: View {
    let tint: SpaceTint
    let color: Color
    /// Small previews sit on a busy dark card and need the wash louder than
    /// the window does to read at a glance.
    var strength: Double = 1

    var body: some View {
        if tint.grain > 0 {
            fill.overlay { SpaceGrain(amount: tint.grain).mask { fill } }
        } else {
            fill
        }
    }

    @ViewBuilder private var fill: some View {
        switch tint.wash {
        case .glow: fade(color)
        case .aurora: aurora
        case .none: Color.clear
        }
    }

    /// A hue drift from the Space color to its neighbor, so the band reads
    /// like light rather than paint.
    private var aurora: some View {
        let rgb = SpaceTintColor.rgb(of: color)
        let neighbor = SpaceRGB(hue: rgb.hue + 0.14, saturation: rgb.saturation, brightness: rgb.brightness)
        return LinearGradient(
            colors: [color, SpaceTintColor.color(neighbor), color.opacity(0.6)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask { fade(.white) }
    }

    private func fade(_ color: Color) -> some View {
        LinearGradient(
            stops: [
                .init(color: color.opacity(min(0.3 * strength, 1)), location: 0),
                .init(color: color.opacity(min(0.14 * strength, 1)), location: 0.45),
                .init(color: .clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
