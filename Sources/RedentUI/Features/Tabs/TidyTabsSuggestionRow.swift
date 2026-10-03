import RedentDesign
import RedentKit
import SwiftUI

struct TidyTabsSuggestionRow: View {
    let count: Int
    let onTidy: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Metric.tightGutter + 4) {
            ChromeOrb(
                systemImage: "archivebox",
                tint: SpacePalette.color("blue"),
                isSelected: false,
                size: 22
            )
            Text("Tidy \(count) unused tabs")
                .font(.system(size: 12))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
            Spacer(minLength: 0)
            Button("Tidy", action: onTidy)
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
                .fill(SpacePalette.color("blue").opacity(0.10))
        }
    }
}

struct TidyTabsBanner: View {
    @Bindable var model: BrowserModel

    var body: some View {
        if model.showTidyTabsSuggestion {
            TidyTabsSuggestionRow(
                count: model.tidyTabsCandidateIDs.count,
                onTidy: { model.tidyUnusedTabs() },
                onDismiss: model.dismissTidyTabsSuggestion
            )
            .padding(.horizontal, Metric.gutter - 2)
            .padding(.bottom, 4)
        }
    }
}
