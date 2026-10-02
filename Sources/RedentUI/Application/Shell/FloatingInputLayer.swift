import SwiftUI

/// Hosts ⌘K and ⌘T over the page. A click outside asks the open panel to
/// close, so it leaves with the same motion as Escape instead of vanishing.
struct FloatingInputLayer: View {
    @Bindable var model: BrowserModel
    @State private var dismissRequest = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.18).onTapGesture { dismissRequest += 1 }
            GeometryReader { geometry in
                panel
                    .frame(maxWidth: .infinity)
                    .padding(.top, max(20, (geometry.size.height - FloatingNewTabView.expandedHeight) / 2))
                    .padding(.leading, pageLeadingInset)
            }
        }
    }

    @ViewBuilder
    private var panel: some View {
        if model.showsCommandBar {
            CommandBarView(model: model.commandBar, space: model.currentSpace,
                           dismissRequest: dismissRequest, onDismiss: model.dismissCommands)
        } else {
            FloatingNewTabView(model: model, dismissRequest: dismissRequest)
        }
    }

    /// The panel belongs to the page, so it centers on the page column rather
    /// than on a window that also holds the rail.
    private var pageLeadingInset: CGFloat {
        model.isSidebarVisible ? model.settings.sidebarWidth : 0
    }
}
