import RedentDesign
import SwiftUI

/// The rows under a text field. Drawn in a panel of its own, so it can hang
/// past the page's edge the way Chrome's does and never touches the page DOM.
struct FormSuggestionList: View {
    @Bindable var model: BrowserModel
    @State private var hovered: String?

    static let rowHeight: CGFloat = 28
    static let padding: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let menu = model.formHistory.menu {
                ForEach(Array(menu.items.enumerated()), id: \.element) { index, value in
                    FormSuggestionRow(
                        value: value,
                        typed: menu.typed,
                        isLit: index == menu.highlighted || hovered == value,
                        onChoose: { model.chooseFormSuggestion(value) },
                        onForget: { model.forgetFormSuggestion(value) }
                    )
                    .onHover { inside in
                        if inside { hovered = value } else if hovered == value { hovered = nil }
                    }
                }
            }
        }
        .padding(Self.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                .fill(Palette.dropdownBase)
                .strokeBorder(Palette.hairline, lineWidth: Metric.hairWidth)
        }
        .clipShape(RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous))
    }

    static func height(forRows count: Int) -> CGFloat {
        CGFloat(count) * rowHeight + padding * 2
    }
}

/// One remembered value. The cross forgets it — nothing else ever does.
private struct FormSuggestionRow: View {
    let value: String
    let typed: String
    let isLit: Bool
    let onChoose: () -> Void
    let onForget: () -> Void

    var body: some View {
        HStack(spacing: Metric.tightGutter) {
            Text(MatchHighlight.attributed(value, matching: typed))
                .font(.system(size: 12.5))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: Metric.tightGutter)
            if isLit {
                Button(action: onForget) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Palette.chromeSecondaryText)
                        .frame(width: 18, height: 18)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .help("Remove from suggestions")
            }
        }
        .padding(.horizontal, 8)
        .frame(height: FormSuggestionList.rowHeight)
        .background {
            RoundedRectangle(cornerRadius: Metric.smallRadius, style: .continuous)
                .fill(isLit ? Palette.accent.opacity(0.18) : .clear)
        }
        .contentShape(.rect)
        .onTapGesture(perform: onChoose)
    }
}
