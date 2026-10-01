import RedentDesign
import RedentKit
import SwiftUI

/// The icon catalog, tinted with the color picked a step earlier and
/// filterable by what the Space is for. The grid is lazy, so only the rows on
/// screen are ever built, however large the catalog grows.
struct SpaceIconGrid: View {
    @Binding var selection: String
    let tint: Color

    @State private var category: SpaceIconCategory?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 9)

    var body: some View {
        VStack(spacing: 10) {
            SpaceIconFilterBar(category: $category, tint: tint)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(icons, id: \.self) { icon in
                        cell(icon)
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.never)
            .contentMargins(.vertical, 4, for: .scrollContent)
            .mask { Self.edgeFade }
        }
        .padding(.horizontal, 4)
    }

    /// Rows dissolve into the edges instead of being sliced by them.
    private static let edgeFade = LinearGradient(
        stops: [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.06),
            .init(color: .black, location: 0.92),
            .init(color: .clear, location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private var icons: [String] {
        category?.icons ?? SpaceIdentity.pickerIcons
    }

    private func cell(_ icon: String) -> some View {
        let isSelected = icon == selection
        return Button {
            withAnimation(.spring(duration: 0.25)) { selection = icon }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : tint)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background {
                    RoundedRectangle(cornerRadius: Metric.smallRadius + 2, style: .continuous)
                        .fill(tint.opacity(isSelected ? 0.9 : 0.14))
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help(icon)
        .accessibilityLabel(icon)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
