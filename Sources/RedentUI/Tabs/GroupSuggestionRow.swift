import RedentDesign
import RedentKit
import SwiftUI

/// A suggested cluster: reason on the left, accept/dismiss as quiet chips.
struct GroupSuggestionRow: View {
    let suggestion: GroupingSuggestion
    let onGroup: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Metric.tightGutter + 4) {
            ChromeOrb(
                systemImage: "sparkles",
                tint: SpacePalette.color("violet"),
                isSelected: false,
                size: 22
            )
            Text(suggestion.reason)
                .font(.system(size: 12))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
            Spacer(minLength: 0)
            Button("Group", action: onGroup)
                .font(.system(size: 11, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundStyle(Palette.chromeText)
            Button("Dismiss", action: onDismiss)
                .font(.system(size: 11, weight: .medium))
                .buttonStyle(.plain)
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
        .background {
            RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                .fill(SpacePalette.color("violet").opacity(0.10))
        }
    }
}
