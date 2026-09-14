import RedentDesign
import RedentKit
import SwiftUI

/// The active Space sets the home page's ambient light, so switching profiles
/// feels like arriving somewhere distinct without changing the chrome.
struct NewTabBackdrop: View {
    let space: BrowserSpace?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Palette.canvas
            RadialGradient(
                colors: [ambientColor.opacity(scheme == .dark ? 0.32 : 0.20), .clear],
                center: UnitPoint(x: 0.5, y: 0.12), startRadius: 10, endRadius: 520
            )
            RadialGradient(
                colors: [ambientColor.opacity(scheme == .dark ? 0.22 : 0.12), .clear],
                center: UnitPoint(x: 0.12, y: 0.9), startRadius: 10, endRadius: 460
            )
            NoiseOverlay(opacity: 0.04)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.25), value: colorToken)
    }

    private var colorToken: String {
        guard let space else { return "" }
        return SpaceIdentity.look(id: space.id, icon: space.icon, colorToken: space.colorToken).colorToken
    }

    private var ambientColor: Color { SpacePalette.color(colorToken) }
}
