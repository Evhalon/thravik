import RedentDesign
import RedentKit
import SwiftUI

/// The named Space hues as swatches; the picked one wears a check. Picking
/// one swaps the hue but keeps the vividness already dialed in.
///
/// Rows are justified edge to edge so the swatches line up with the hue strip
/// and wash cards below instead of floating in the middle.
struct SpaceColorGrid: View {
    @Binding var tint: SpaceTint

    private static let perRow = 10
    private static let rows: [[String]] = stride(from: 0, to: SpaceIdentity.pickerTokens.count, by: perRow).map {
        Array(SpaceIdentity.pickerTokens[$0..<min($0 + perRow, SpaceIdentity.pickerTokens.count)])
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Self.rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.element) { index, token in
                        if index > 0 { Spacer(minLength: 4) }
                        swatch(token)
                    }
                }
            }
        }
    }

    private func swatch(_ token: String) -> some View {
        let isSelected = tint.base == .named(token)
        let color = SpacePalette.color(token)
        return Button {
            withAnimation(.spring(duration: 0.25)) { tint.base = .named(token) }
        } label: {
            Circle()
                .fill(color)
                .overlay { Circle().strokeBorder(.white.opacity(isSelected ? 0.9 : 0.18), lineWidth: isSelected ? 2 : 1) }
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(isSelected ? 1 : 0)
                }
                .frame(width: 26, height: 26)
                .scaleEffect(isSelected ? 1.1 : 1)
                .shadow(color: color.opacity(0.5), radius: isSelected ? 6 : 0, y: isSelected ? 2 : 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(token.capitalized)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
