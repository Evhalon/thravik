import RedentDesign
import RedentKit
import SwiftUI

/// Search engine and homepage — the two settings people reach for first.
struct GeneralSettingsPane: View {
    @Binding var settings: BrowserSettings
    let locks: Set<ManagedPolicyLockKey>
    let defaultBrowser: DefaultBrowserModel
    let onResetWorkspace: () -> Void
    @State private var isConfirmingReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SearchSettingsSection(settings: $settings, locks: locks)
            SettingsSection("TIDY TABS") {
                Picker("Archive unused tabs after", selection: $settings.tidyTabsThreshold) {
                    ForEach(TidyTabsThreshold.allCases) { threshold in
                        Text(threshold.label).tag(threshold)
                    }
                }
                .pickerStyle(.menu)
                Text("Suggests archiving loose tabs you have not opened in a while. Off by default.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            SettingsSection("HOMEPAGE") {
                TextField("https://…", text: $settings.homepage)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.chromeText)
                    .padding(.horizontal, 12)
                    .frame(height: Metric.controlHeight)
                    .background { fieldChrome }
                    .managedPolicyLocked(locks.contains(.homepage))
            }
            SettingsSection("VIDEO") {
                SettingsToggleRow(
                    "Automatically float playing videos when switching tabs",
                    caption: "Keeps a playing video visible in a floating window until you return to its tab.",
                    isOn: $settings.floatsPlayingVideoOnTabSwitch
                )
            }
            SettingsSection("STARTUP") {
                SettingsToggleRow(
                    "Reopen tabs on launch",
                    caption: "Open the tabs that were active when you last quit.",
                    isOn: $settings.reopensTabsOnLaunch
                )
            }
            CalendarSettingsSection(settings: $settings)
            SettingsSection("DEFAULT BROWSER") {
                DefaultBrowserRow(model: defaultBrowser)
            }
            SettingsSection("RESET") {
                resetRow
            }
        }
        .alert("Reset workspace?", isPresented: $isConfirmingReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Workspace", role: .destructive, action: onResetWorkspace)
        } message: {
            Text("This closes every tab and removes custom Spaces and tab groups. History, bookmarks, and passwords are kept.")
        }
    }

    private var fieldChrome: some View {
        RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
            .fill(Palette.chromeFill)
            .overlay {
                RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: Metric.hairWidth)
            }
    }

    private var resetRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Start with a clean workspace")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.chromeText)
                Text("Keeps history, bookmarks, and passwords.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            Spacer(minLength: Metric.gutter)
            Button("Reset…", role: .destructive) { isConfirmingReset = true }
        }
    }
}
