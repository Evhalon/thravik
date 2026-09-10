import RedentDesign
import RedentKit
import SwiftUI

/// Search engine and homepage — the two settings people reach for first.
struct GeneralSettingsPane: View {
    @Binding var settings: BrowserSettings
    let defaultBrowser: DefaultBrowserModel
    let onResetWorkspace: () -> Void
    @State private var isConfirmingReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection("SEARCH") {
                HStack {
                    Text("Engine")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.chromeText)
                    Spacer(minLength: Metric.gutter)
                    Picker("Search engine", selection: engineSelection) {
                        ForEach(SearchEngine.allCases) { engine in
                            Text(engine.label).tag(engine)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }
            }
            SettingsSection("HOMEPAGE") {
                TextField("https://…", text: $settings.homepage)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.chromeText)
                    .padding(.horizontal, 12)
                    .frame(height: Metric.controlHeight)
                    .background { fieldChrome }
            }
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

    /// Routed through the model so the homepage follows the engine.
    private var engineSelection: Binding<SearchEngine> {
        Binding(get: { settings.searchEngine }, set: { settings.selectSearchEngine($0) })
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
