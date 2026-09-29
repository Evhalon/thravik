import RedentDesign
import SwiftUI

/// Keeps the window buttons clear while leaving a way back to the sidebar.
struct WindowControlsClearance: View {
    @Bindable var model: BrowserModel

    var body: some View {
        HStack(spacing: 0) {
            ChromeButton(systemImage: "sidebar.left", help: "Show sidebar (⌘B)", action: model.toggleSidebar)
                .accessibilityLabel("Show sidebar")
            Spacer(minLength: 0)
        }
        .padding(.leading, Metric.windowButtonsWidth)
        .frame(height: Metric.windowButtonsHeight)
        .background { TitlebarDragRegion() }
    }
}
