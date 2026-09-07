import RedentDesign
import SwiftUI

/// The Chrome-style toolbar row, used when tabs live along the top edge.
struct TopToolbar: View {
    @Bindable var model: BrowserModel

    var body: some View {
        HStack(spacing: Metric.tightGutter) {
            SpaceSwitcher(model: model).frame(minWidth: 108, maxWidth: 168)
            NavigationControls(model: model)
                .frame(width: 132)
            AddressField(model: model)
                .frame(maxWidth: 720)
                .zIndex(2)
            Spacer(minLength: 0)
            Menu {
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
        .padding(.horizontal, Metric.gutter)
        .frame(height: Metric.toolbarHeight)
    }
}
