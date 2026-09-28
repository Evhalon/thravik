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
            let color = SpacePalette.color(look(space).colorToken)
            LinearGradient(
                stops: [
                    .init(color: color.opacity(0.3), location: 0),
                    .init(color: color.opacity(0.14), location: 0.45),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 170)
            .allowsHitTesting(false)
        }
    }

    private func look(_ space: BrowserSpace) -> SpaceIdentity.Look {
        SpaceIdentity.look(id: space.id, icon: space.icon, colorToken: space.colorToken)
    }
}
