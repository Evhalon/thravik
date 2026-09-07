import RedentDesign
import SwiftUI

/// New-tab affordance plus the doors to the vault and settings.
struct SidebarFooter: View {
    @Bindable var model: BrowserModel
    @State private var isHoveringNew = false

    var body: some View {
        HStack(spacing: Metric.tightGutter) {
            newTabButton
            menu
        }
    }

    private var newTabButton: some View {
        Button(action: model.openNewTab) {
            HStack(spacing: Metric.tightGutter + 2) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                Text("New Tab")
                    .font(.system(size: 12, weight: .medium))
                Spacer(minLength: 0)
            }
            .foregroundStyle(Palette.chromeSecondaryText)
            .padding(.horizontal, Metric.tightGutter + 4)
            .frame(height: Metric.tabRowHeight)
            .contentShape(.rect)
        }
        .buttonStyle(PressScaleStyle())
        .chromeHoverEffect(isActive: isHoveringNew)
        .onHover { isHoveringNew = $0 }
    }

    private var menu: some View {
        Menu {
            Button("History…") { model.sheet = .history }
            Button("Bookmarks…") { model.sheet = .bookmarks }
            Button("Passwords…") { model.sheet = .passwords }
            Button("Authenticator…") { model.sheet = .authenticator }
            Divider()
            Button("Import from another browser…") { model.sheet = .importBrowser }
            Divider()
            Button("Settings…") { model.sheet = .settings }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .semibold))
                .frame(width: Metric.controlHeight, height: Metric.controlHeight)
                .contentShape(.rect)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .foregroundStyle(Palette.chromeSecondaryText)
    }
}
