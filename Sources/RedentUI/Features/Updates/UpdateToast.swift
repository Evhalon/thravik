import RedentDesign
import RedentKit
import SwiftUI

/// A small corner notice that a newer release is out. Installing still waits
/// for the user's click — the popup only makes the offer visible.
struct UpdateToast: View {
    let updates: UpdateModel
    let release: AppRelease

    var body: some View {
        HStack(spacing: Metric.gutter) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Palette.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text("Update available")
                    .font(.system(size: 12, weight: .semibold))
                Text("Version \(release.version.description)")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            Spacer(minLength: Metric.tightGutter)
            Button("Restart") {
                Task { await updates.installAndRestart(release) }
            }
            .help("Download update \(release.version.description) and restart")
            dismissButton
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.vertical, Metric.tightGutter + 2)
        .frame(width: 280)
        .glassPanel()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Update \(release.version.description) available")
    }

    private var dismissButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { updates.dismissAnnouncement() }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Palette.chromeSecondaryText)
                .frame(width: 18, height: 18)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .help("Not now")
        .accessibilityLabel("Dismiss update notice")
    }
}
