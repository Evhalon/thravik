import RedentDesign
import RedentKit
import SwiftUI

/// The address bar dropdown.
///
/// Row 0 is lit whenever nothing is armed, because it is what return does.
/// Hover only tints: pointing at a row must not change what the keyboard
/// will open.
struct SuggestionList: View {
    @Bindable var model: BrowserModel
    @State private var hoveredID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(Array(model.suggestions.rows.enumerated()), id: \.element.id) { index, row in
                SuggestionRow(
                    suggestion: row,
                    query: model.suggestions.query,
                    emphasis: emphasis(at: index, for: row),
                    onOpen: { model.open(row, inNewTab: $0) }
                )
                .onHover { inside in
                    if inside { hoveredID = row.id } else if hoveredID == row.id { hoveredID = nil }
                }
            }
        }
        .padding(5)
        .background {
            // Opaque base: the glass alone lets whatever is behind bleed
            // through, and a suggestion list has to be readable, not pretty.
            RoundedRectangle(cornerRadius: Metric.mediumRadius + 3, style: .continuous)
                .fill(Palette.dropdownBase)
        }
        .floatingGlass(in: RoundedRectangle(cornerRadius: Metric.mediumRadius + 3, style: .continuous))
        .animation(.snappy(duration: 0.14), value: model.suggestions.rows.map(\.id))
        .animation(.snappy(duration: 0.1), value: model.suggestions.highlighted)
        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
    }

    private func emphasis(at index: Int, for row: AddressSuggestion) -> SuggestionRow.Emphasis {
        if index == (model.suggestions.highlighted ?? 0) { return .active }
        return hoveredID == row.id ? .hovered : .plain
    }
}
