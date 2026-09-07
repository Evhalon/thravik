import RedentDesign
import RedentKit
import SwiftUI

/// Tab layout, tab-strip visibility, and the sidebar width slider.
struct AppearanceSettingsPane: View {
    @Binding var settings: BrowserSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection("TAB LAYOUT") {
                HStack(spacing: Metric.gutter) {
                    ForEach(TabLayout.allCases) { layout in
                        TabLayoutPickerCard(
                            layout: layout,
                            isSelected: settings.tabLayout == layout
                        ) {
                            settings.tabLayout = layout
                        }
                    }
                }
            }
            SettingsSection("CHROME") {
                SettingsToggleRow("Show tab strip", isOn: $settings.isTabStripVisible)
                sidebarWidthSlider
            }
        }
    }

    private var sidebarWidthSlider: some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter) {
            HStack {
                Text("Sidebar width")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.chromeText)
                Spacer()
                Text("\(Int(settings.sidebarWidth.rounded()))")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .monospacedDigit()
            }
            Slider(value: $settings.sidebarWidth, in: BrowserSettings.sidebarWidthRange)
                .disabled(settings.tabLayout != .sidebar)
            if settings.tabLayout != .sidebar {
                Text("Used when the tab layout is Sidebar.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
        }
        .opacity(settings.tabLayout == .sidebar ? 1 : 0.45)
        .padding(.top, 4)
    }
}
