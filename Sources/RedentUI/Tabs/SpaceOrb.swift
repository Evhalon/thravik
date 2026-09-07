import RedentDesign
import RedentKit
import SwiftUI

/// Resolves a Space's stored (or derived) look into a `ChromeOrb`.
struct SpaceOrb: View {
    let space: BrowserSpace
    var isSelected = false
    var size: CGFloat = 26

    var body: some View {
        ChromeOrb(
            systemImage: look.icon,
            tint: SpacePalette.color(look.colorToken),
            isSelected: isSelected,
            size: size
        )
    }

    private var look: SpaceIdentity.Look {
        SpaceIdentity.look(id: space.id, icon: space.icon, colorToken: space.colorToken)
    }
}
