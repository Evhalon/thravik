import RedentDesign
import RedentKit
import SwiftUI

/// Search engine and homepage — the two settings people reach for first.
struct GeneralSettingsPane: View {
    @Binding var settings: BrowserSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection("SEARCH") {
                HStack {
                    Text("Engine")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.chromeText)
                    Spacer(minLength: Metric.gutter)
                    Picker("Search engine", selection: $settings.searchEngine) {
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
}
