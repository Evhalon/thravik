import RedentDesign
import SwiftUI

struct BrowserMenu: View {
    @Bindable var model: BrowserModel
    var symbol = "ellipsis.circle"
    var showsPageActions = false
    @State private var isShowingVolume = false

    var body: some View {
        Menu {
            if showsPageActions { pageActions }
            Button("New Window", action: model.newWindow)
            Button("New Private Window", action: model.newPrivateWindow)
            Divider()
            Button("Downloads…") { model.sheet = .downloads }
            Button("Bookmarks…") { model.sheet = .bookmarks }
            Button("History…") { model.sheet = .history }
            Divider()
            Button("Passwords…") { model.sheet = .passwords }
            Button("Authenticator…") { model.sheet = .authenticator }
            Divider()
            Button("Settings…") { model.sheet = .settings }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(width: Metric.controlHeight, height: Metric.controlHeight)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .foregroundStyle(Palette.chromeSecondaryText)
        .accessibilityLabel("Browser menu")
        .popover(isPresented: $isShowingVolume) { TabVolumePopover(model: model) }
    }

    @ViewBuilder
    private var pageActions: some View {
        Button(model.isPageLoading ? "Stop Loading" : "Reload") {
            if model.isPageLoading { model.stopLoading() } else { model.reloadPage() }
        }
        .disabled(!model.hasPage)
        Button(model.isSidebarVisible ? "Hide Sidebar" : "Keep Sidebar Open", action: model.toggleSidebar)
        if model.showsVolumeControl { Button("Tab Volume…") { isShowingVolume = true } }
        if model.showsFloatVideoControl {
            Button(model.isVideoFloating ? "Return Video to Tab" : "Float Video", action: model.toggleFloatingVideo)
        }
        Divider()
    }
}
