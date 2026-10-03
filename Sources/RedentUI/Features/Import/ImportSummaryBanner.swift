import RedentDesign
import RedentKit
import SwiftUI

struct ImportSummaryBanner: View {
    let summary: ImportSummary
    let problem: String?
    let onBack: () -> Void
    let onDone: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Metric.gutter) {
            result.frame(maxHeight: .infinity)
            HStack {
                Button("Back to import options", action: onBack)
                Spacer()
                Button("Done", action: onDone).buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var result: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)
            Image(systemName: symbol)
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(problem == nil ? Palette.accent : Palette.danger)
                .symbolEffect(.bounce, options: .nonRepeating, isActive: !reduceMotion)
            VStack(spacing: 8) {
                Text(title).font(.system(size: 26, weight: .semibold, design: .rounded))
                Text(subtitle).font(.system(size: 13))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .multilineTextAlignment(.center)
            }
            counts
            if let problem { warning(problem) }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private var symbol: String {
        if problem != nil { return "exclamationmark.circle" }
        return summary.isEmpty ? "tray" : "checkmark.circle.fill"
    }

    private var title: String {
        if problem != nil { return "Import finished with issues" }
        return summary.isEmpty ? "Nothing new to import" : "Import complete"
    }

    private var subtitle: String {
        if problem != nil { return "Review the details below. Successfully imported data is kept." }
        return summary.isEmpty ? "No new items were added from the selected profiles." : "Your imported data is ready in Thravik."
    }

    private var counts: some View {
        HStack(spacing: Metric.gutter) {
            count(summary.history, title: "Pages", symbol: "clock")
            count(summary.bookmarks, title: "Bookmarks", symbol: "bookmark")
            count(summary.passwords, title: "Passwords", symbol: "key")
        }
        .padding(18)
        .background(Palette.chromeFill, in: .rect(cornerRadius: Metric.mediumRadius))
    }

    private func count(_ value: Int, title: String, symbol: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: symbol).foregroundStyle(Palette.chromeSecondaryText)
            Text(value, format: .number).font(.system(size: 22, weight: .semibold, design: .rounded))
            Text(title).font(.system(size: 11)).foregroundStyle(Palette.chromeSecondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func warning(_ message: String) -> some View {
        ScrollView {
            Text(message).font(.system(size: 12)).foregroundStyle(Palette.danger)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 110)
        .padding(14)
        .background(Palette.danger.opacity(0.08), in: .rect(cornerRadius: Metric.smallRadius))
    }
}
