import RedentDesign
import SwiftUI

/// The address bar dropdown.
struct SuggestionList: View {
    @Bindable var model: BrowserModel

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(Array(model.suggestions.rows.enumerated()), id: \.element.id) { index, row in
                SuggestionRow(
                    suggestion: row,
                    isHighlighted: index == model.suggestions.highlighted,
                    onOpen: { model.open(row.url, inNewTab: $0) },
                    onHover: { model.suggestions.highlighted = index }
                )
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
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
