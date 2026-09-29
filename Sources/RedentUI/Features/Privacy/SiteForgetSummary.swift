import RedentDesign
import RedentKit
import SwiftUI

/// The result of a Forget pass, stated plainly. It reports what happened, and
/// says so when nothing was found rather than implying a successful erasure.
struct SiteForgetSummary: View {
    let report: ForgetSiteReport

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(headline).font(.system(size: 12, weight: .semibold))
            ForEach(lines, id: \.self) { line in
                Text(line).font(.system(size: 11)).foregroundStyle(Palette.chromeSecondaryText)
            }
        }
        .padding(Metric.tightGutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(radius: Metric.mediumRadius)
    }

    private var headline: String {
        report.removedNothing
            ? "Nothing stored for \(report.domain) was found"
            : "Removed for \(report.domain)"
    }

    private var lines: [String] {
        var lines: [String] = []
        if !report.removedRecords.isEmpty {
            lines.append("Website data in \(report.clearedContainers) Container(s)")
        }
        if report.clearedHistory { lines.append("History entries") }
        if report.discardedClosedTabs > 0 {
            lines.append("\(report.discardedClosedTabs) reopenable closed tab(s)")
        }
        lines.append("Kept: \(report.retained.joined(separator: ", "))")
        if !report.failures.isEmpty {
            lines.append("Could not remove: \(report.failures.joined(separator: ", "))")
        }
        return lines
    }
}
