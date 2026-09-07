import RedentDesign
import SwiftUI

/// Back / forward / reload / hide-tabs. Shared by both layouts.
struct NavigationControls: View {
    @Bindable var model: BrowserModel

    var body: some View {
        HStack(spacing: 1) {
            ChromeButton(
                systemImage: "sidebar.left",
                help: model.showsTabStrip ? "Hide tabs (⌘\\)" : "Show tabs (⌘\\)",
                action: model.toggleTabStrip
            )
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
            ChromeButton(
                systemImage: isLoading ? "xmark" : "arrow.clockwise",
                help: isLoading ? "Stop" : "Reload",
                isEnabled: model.selectedTab != nil
            ) {
                if isLoading { model.selectedTab?.stopLoading() } else { model.selectedTab?.reload() }
            }
        }
    }

    private var isLoading: Bool { model.selectedTab?.isLoading ?? false }
}
