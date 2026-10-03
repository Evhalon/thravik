import RedentDesign
import RedentKit
import SwiftUI

/// Tab layout, tab-strip visibility, the sidebar width slider, and group naming.
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
            chromeSection
            SettingsSection("TAB GROUPS") {
                SettingsToggleRow(
                    "Name groups with Apple Intelligence",
                    caption: "Runs on this Mac, using only tab titles and sites. Groups show the site name when off.",
                    isOn: $settings.namesGroupsOnDevice
                )
            }
        }
    }

    private var chromeSection: some View {
        SettingsSection("CHROME") {
            SettingsToggleRow(
                "Floating new tab search",
                caption: "\(key(.newTab)) opens a search above the current page. Press Return to open a tab.",
                isOn: $settings.opensFloatingNewTab
            )
            SettingsToggleRow(
                "Hide top navigation bar",
                caption: "Collapse with \(key(.toggleSidebar)) for a full-height page. "
                    + "Hover the left or top edge to reveal controls.",
                isOn: hiddenNavigationSelection
            )
            SettingsToggleRow(
                "Show tab strip",
                caption: "Toggle with \(key(.toggleTabStrip)).",
                isOn: $settings.isTabStripVisible
            )
            SettingsToggleRow(
                "Show bookmarks bar",
                caption: "Toggle with \(key(.showBookmarksBar)). Hidden in Focus Mode.",
                isOn: $settings.showsBookmarksBar
            )
            sidebarWidthSlider
        }
    }

    /// The bound key, or the command's name once the user has cleared it.
    private func key(_ id: ShortcutID) -> String {
        settings.shortcutBindings.chord(for: id)?.displayString ?? id.title
    }

    private var hiddenNavigationSelection: Binding<Bool> {
        Binding(get: { settings.hidesNavigationBar }, set: { settings.setNavigationBarHidden($0) })
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
