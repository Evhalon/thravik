import RedentDesign
import RedentKit
import SwiftUI

/// Three tiny previews of how the Space color pools across the window top.
struct SpaceWashPicker: View {
    @Binding var tint: SpaceTint
    let color: Color

    private static let card = RoundedRectangle(cornerRadius: Metric.smallRadius + 1, style: .continuous)

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SpaceTint.Wash.allCases, id: \.self) { wash in
                option(wash)
            }
        }
    }

    private func option(_ wash: SpaceTint.Wash) -> some View {
        let isSelected = tint.wash == wash
        var preview = tint
        preview.wash = wash
        // The cards compare wash shapes only; grain belongs to the Space itself.
        preview.grain = 0
        return Button {
            withAnimation(.spring(duration: 0.25)) { tint.wash = wash }
        } label: {
            Text(title(wash))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? Palette.chromeText : Palette.chromeSecondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background {
                    ZStack {
                        Self.card.fill(.black.opacity(0.22))
                        SpaceWashFill(tint: preview, color: color, strength: 2.6)
                    }
                    .clipShape(Self.card)
                }
                .overlay {
                    Self.card.strokeBorder(isSelected ? color : .white.opacity(0.12), lineWidth: isSelected ? 1.5 : 1)
                }
                .contentShape(Self.card)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title(wash)) wash")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func title(_ wash: SpaceTint.Wash) -> String {
        switch wash {
        case .glow: "Glow"
        case .aurora: "Aurora"
        case .none: "None"
        }
    }
}
