import RedentDesign
import RedentKit
import SwiftUI

/// The composer's color step: a named swatch or any hue, how vivid and how
/// grainy it should run, and how it washes across the top of the window.
struct SpaceColorStep: View {
    @Binding var token: String

    var body: some View {
        let current = SpaceTint(token: token)
        let color = SpaceTintColor.color(token)
        VStack(spacing: 14) {
            SpaceColorGrid(tint: tint)
            SpaceHueStrip(tint: tint)
            HStack(spacing: 10) {
                SpaceVividnessWave(tint: current, color: color)
                SpaceDialKnob(title: "Vivid", value: dial(\.vividness), resting: SpaceTint.neutralVividness, color: color)
                SpaceDialKnob(title: "Grain", value: dial(\.grain), resting: 0, color: color)
            }
            SpaceWashPicker(tint: tint, color: color)
        }
        .padding(.horizontal, 4)
    }

    private var tint: Binding<SpaceTint> {
        Binding(
            get: { SpaceTint(token: token) },
            set: { token = $0.token }
        )
    }

    private func dial(_ keyPath: WritableKeyPath<SpaceTint, Double>) -> Binding<Double> {
        Binding(
            get: { SpaceTint(token: token)[keyPath: keyPath] },
            set: { tint.wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}
