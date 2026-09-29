import RedentDesign
import RedentKit
import SwiftUI

/// What actually came across, in counts.
struct ImportSummaryBanner: View {
    let summary: ImportSummary
    let problem: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: Metric.tightGutter) {
                Image(systemName: summary.isEmpty ? "exclamationmark.circle" : "checkmark.circle.fill")
                    .foregroundStyle(summary.isEmpty ? Palette.chromeSecondaryText : .green)
                Text(summary.isEmpty ? "Nothing new to import" : line)
                    .font(.system(size: 12))
            }
            if let problem {
                Text(problem)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Metric.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Metric.smallRadius, style: .continuous)
                .fill(Palette.chromeFill)
        }
    }

    private var line: String {
        var parts: [String] = []
        if summary.history > 0 { parts.append("\(summary.history) pages") }
        if summary.bookmarks > 0 { parts.append("\(summary.bookmarks) bookmarks") }
        if summary.passwords > 0 { parts.append("\(summary.passwords) passwords") }
        return "Imported " + parts.joined(separator: ", ")
    }
}
