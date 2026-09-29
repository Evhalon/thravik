import RedentDesign
import SwiftUI

/// Shown when the temporary tab the user is reading reaches its deadline.
/// Nothing closes behind their back — the choice is theirs.
struct TemporaryTabBar: View {
    let title: String
    let onKeep: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: Metric.gutter) {
            Image(systemName: "clock.badge.xmark")
                .foregroundStyle(Palette.chromeSecondaryText)
            VStack(alignment: .leading, spacing: 1) {
                Text("This temporary tab has expired")
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: Metric.gutter)
            Button("Keep Tab", action: onKeep)
            Button("Close", action: onClose).keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.vertical, Metric.tightGutter)
        .glassPanel()
    }
}
