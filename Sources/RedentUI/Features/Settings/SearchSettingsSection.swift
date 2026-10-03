import RedentDesign
import RedentKit
import SwiftUI

/// Default engine picker plus the user's own engines.
struct SearchSettingsSection: View {
    @Binding var settings: BrowserSettings
    let locks: Set<ManagedPolicyLockKey>

    var body: some View {
        SettingsSection("SEARCH") {
            HStack {
                Text("Engine")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.chromeText)
                Spacer(minLength: Metric.gutter)
                Picker("Search engine", selection: selection) {
                    ForEach(SearchEngine.allCases) { engine in
                        Text(engine.label).tag(SearchEngineSelection.builtIn(engine))
                    }
                    if !settings.customSearchEngines.isEmpty {
                        Divider()
                        ForEach(settings.customSearchEngines) { engine in
                            Text(engine.name).tag(SearchEngineSelection.custom(engine.id))
                        }
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
                .disabled(locks.contains(.searchEngine))
            }
            if locks.contains(.searchEngine) { ManagedPolicyCaption() }
            if !settings.customSearchEngines.isEmpty {
                customList
            }
            if !locks.contains(.searchEngine) {
                CustomSearchEngineForm(settings: $settings)
            }
        }
    }

    private var selection: Binding<SearchEngineSelection> {
        Binding(get: { settings.searchSelection }, set: { settings.select($0) })
    }

    private var customList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(settings.customSearchEngines) { engine in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(engine.name)
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.chromeText)
                        Text("\(engine.keyword) · \(engine.template)")
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.chromeSecondaryText)
                            .lineLimit(1)
                    }
                    Spacer(minLength: Metric.gutter)
                    if !locks.contains(.searchEngine) {
                        Button("Remove") { settings.removeCustomSearchEngine(id: engine.id) }
                    }
                }
            }
        }
    }
}
