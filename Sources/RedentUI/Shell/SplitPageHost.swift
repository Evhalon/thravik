import RedentDesign
import RedentKit
import SwiftUI

/// Lays out the window's panes. One pane is the ordinary case and costs exactly
/// what it did before; a second appears only when the user asks for it.
struct SplitPageHost: View {
    @Bindable var model: BrowserModel

    var body: some View {
        if model.split.isSplit, let secondary = model.secondaryTab {
            GeometryReader { proxy in
                if model.split.orientation == .horizontal {
                    HStack(spacing: 0) { panes(secondary, along: proxy.size.width) }
                } else {
                    VStack(spacing: 0) { panes(secondary, along: proxy.size.height) }
                }
            }
        } else {
            PagePane(model: model, tab: model.primaryTab, pane: .primary)
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func panes(_ secondary: any BrowserTab, along extent: CGFloat) -> some View {
        PagePane(model: model, tab: model.primaryTab, pane: .primary)
            .frame(
                width: model.split.orientation == .horizontal ? extent * model.split.ratio : nil,
                height: model.split.orientation == .vertical ? extent * model.split.ratio : nil
            )
        SplitDivider(
            orientation: model.split.orientation,
            onDrag: { delta in
                guard extent > 0 else { return }
                model.split.setRatio(model.split.ratio + delta / extent)
            }
        )
        PagePane(model: model, tab: secondary, pane: .secondary)
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
    }
}
