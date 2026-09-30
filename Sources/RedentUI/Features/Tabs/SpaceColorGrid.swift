import RedentDesign
import RedentKit
import SwiftUI

/// The Space hues as swatches; the picked one wears a check.
struct SpaceColorGrid: View {
    @Binding var selection: String

    private let columns = Array(repeating: GridItem(.fixed(38), spacing: 10), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(SpaceIdentity.tokens, id: \.self) { token in
                swatch(token)
            }
        }
    }

    private func swatch(_ token: String) -> some View {
        let isSelected = token == selection
        return Button {
            withAnimation(.spring(duration: 0.25)) { selection = token }
        } label: {
            Circle()
                .fill(SpacePalette.color(token))
                .overlay { Circle().strokeBorder(.white.opacity(isSelected ? 0.9 : 0.18), lineWidth: isSelected ? 2 : 1) }
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(isSelected ? 1 : 0)
                }
                .frame(width: 34, height: 34)
                .scaleEffect(isSelected ? 1.08 : 1)
                .shadow(color: SpacePalette.color(token).opacity(isSelected ? 0.5 : 0), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(token.capitalized)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
