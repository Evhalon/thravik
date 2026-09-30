import RedentDesign
import RedentKit
import SwiftUI

/// The icon catalog, tinted with the color picked a step earlier.
struct SpaceIconGrid: View {
    @Binding var selection: String
    let tint: Color

    private let columns = Array(repeating: GridItem(.fixed(34), spacing: 8), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(SpaceIdentity.pickerIcons, id: \.self) { icon in
                cell(icon)
            }
        }
    }

    private func cell(_ icon: String) -> some View {
        let isSelected = icon == selection
        return Button {
            withAnimation(.spring(duration: 0.25)) { selection = icon }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : tint)
                .frame(width: 34, height: 34)
                .background {
                    RoundedRectangle(cornerRadius: Metric.smallRadius + 2, style: .continuous)
                        .fill(tint.opacity(isSelected ? 0.9 : 0.14))
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
