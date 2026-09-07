import AppKit
import RedentDesign
import RedentKit
import SwiftUI

/// One row of the address bar dropdown.
struct SuggestionRow: View {
    let suggestion: AddressSuggestion
    let isHighlighted: Bool
    let onOpen: (_ commandHeld: Bool) -> Void
    let onHover: () -> Void

    var body: some View {
        HStack(spacing: Metric.tightGutter + 2) {
            Image(systemName: suggestion.kind.symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(suggestion.kind == .bookmark ? Palette.accent : Palette.chromeSecondaryText)
                .frame(width: 16)

            Text(suggestion.title)
                .font(.system(size: 12.5))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)

            Text(suggestion.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(Palette.chromeSecondaryText)
                .lineLimit(1)
                .layoutPriority(-1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Metric.tightGutter + 2)
        .frame(height: 28)
        .background {
            RoundedRectangle(cornerRadius: Metric.smallRadius, style: .continuous)
                .fill(isHighlighted ? Palette.accent.opacity(0.30) : .clear)
        }
        .contentShape(.rect)
        .onTapGesture { onOpen(NSEvent.modifierFlags.contains(.command)) }
        .onHover { if $0 { onHover() } }
    }
}
