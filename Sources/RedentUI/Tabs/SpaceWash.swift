import RedentDesign
import RedentKit
import SwiftUI

/// Soft Space color pooling at the top of the rail, like Arc's profile glow.
struct SpaceWash: View {
    let space: BrowserSpace?

    var body: some View {
        if let space {
            EllipticalGradient(
                colors: [SpacePalette.color(look(space).colorToken).opacity(0.34), .clear],
                center: .top,
                startRadiusFraction: 0,
                endRadiusFraction: 0.95
            )
            .frame(height: 170)
            .allowsHitTesting(false)
        }
    }

    private func look(_ space: BrowserSpace) -> SpaceIdentity.Look {
        SpaceIdentity.look(id: space.id, icon: space.icon, colorToken: space.colorToken)
    }
}
