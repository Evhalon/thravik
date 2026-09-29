import RedentDesign
import RedentKit
import SwiftUI

/// The installed version, and the one button that replaces it.
///
/// Opening the pane checks once. That is the only automatic thing here: the
/// download and the restart both wait for a click.
struct UpdatesSettingsPane: View {
    let updates: UpdateModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection("INSTALLED") {
                versionRow
            }
            SettingsSection("UPDATES") {
                UpdateStatusCard(updates: updates)
                Text("Updates are downloaded from the Thravik releases page, checked, and installed when you say so. The app closes and reopens itself on the new version.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .task {
            if updates.phase == .idle { await updates.check() }
        }
    }

    private var versionRow: some View {
        HStack {
            Text("Thravik")
                .font(.system(size: 13))
                .foregroundStyle(Palette.chromeText)
            Spacer(minLength: Metric.gutter)
            Text(updates.currentVersion?.description ?? "Unknown")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.chromeSecondaryText)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .frame(height: Metric.controlHeight)
        .background {
            RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                .fill(Palette.chromeFill)
        }
    }
}
