import RedentDesign
import SwiftUI

/// Back / forward / reload / hide-tabs. Shared by both layouts.
struct NavigationControls: View {
    @Bindable var model: BrowserModel
    var showsTabToggle = true
    var showsReload = true

    var body: some View {
        HStack(spacing: 1) {
            if showsTabToggle {
                ChromeButton(
                    systemImage: "sidebar.left",
                    help: tabToggleHelp,
                    action: model.toggleTabStrip
                )
            }
            Spacer(minLength: 0)
            ChromeButton(
                systemImage: "chevron.left",
                help: "Back",
                isEnabled: model.selectedTab?.canGoBack ?? false
            ) { model.selectedTab?.goBack() }
            ChromeButton(
                systemImage: "chevron.right",
                help: "Forward",
                isEnabled: model.selectedTab?.canGoForward ?? false
            ) { model.selectedTab?.goForward() }
            if showsReload { reloadButton }
        }
    }

    private var reloadButton: some View {
        ChromeButton(
            systemImage: isLoading ? "xmark" : "arrow.clockwise",
            help: isLoading ? "Stop" : "Reload",
            isEnabled: model.selectedTab != nil
        ) {
            if isLoading { model.selectedTab?.stopLoading() } else { model.selectedTab?.reload() }
        }
    }

    private var isLoading: Bool { model.selectedTab?.isLoading ?? false }

    private var tabToggleHelp: String {
        if model.settings.tabLayout == .sidebar {
            return model.isSidebarVisible ? "Hide sidebar (⌘B)" : "Show sidebar (⌘B)"
        }
        return model.showsTabStrip ? "Hide tabs (⌘\\)" : "Show tabs (⌘\\)"
    }
}
