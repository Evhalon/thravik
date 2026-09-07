import RedentDesign
import SwiftUI

/// What is left of the chrome once the tab rail is hidden: a floating bar so
/// the address and the back button stay reachable without giving up the
/// full-width page.
struct CompactChromeBar: View {
    @Bindable var model: BrowserModel

    var body: some View {
        HStack(spacing: Metric.tightGutter) {
            NavigationControls(model: model)
                .frame(width: 134)
            AddressField(model: model)
                .frame(maxWidth: 480)
                .zIndex(2)
        }
        .padding(.horizontal, Metric.tightGutter + 2)
        .padding(.vertical, Metric.tightGutter)
        .floatingGlass(in: RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
        .frame(maxWidth: 680)
        .padding(.top, Metric.gutter + Metric.pageInset)
    }
}
