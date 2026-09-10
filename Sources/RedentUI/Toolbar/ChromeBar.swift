import RedentDesign
import SwiftUI

/// The window's one toolbar row.
///
/// `PageColumn` gives it a row above the page card rather than floating it over
/// the content, so it never covers a site's own header. The same row serves both
/// tab layouts, so the address never moves when the rail is toggled.
struct ChromeBar: View {
    @Bindable var model: BrowserModel

    var body: some View {
        HStack(spacing: Metric.tightGutter) {
            if !model.isSidebarVisible {
                SpaceSwitcher(model: model).frame(minWidth: 96, maxWidth: 168)
            }
            NavigationControls(model: model)
                .frame(width: 132)
            AddressField(model: model)
                .frame(maxWidth: 720)
                .zIndex(2)
            if model.isPrivate { ChromeBadge("PRIVATE", tint: Palette.accent) }
            DownloadsButton(model: model)
            overflowMenu
        }
        .padding(.horizontal, Metric.tightGutter + 2)
        .padding(.vertical, Metric.tightGutter)
    }

    private var overflowMenu: some View {
        Menu {
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
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 13, weight: .medium))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .foregroundStyle(Palette.chromeSecondaryText)
    }
}
