import RedentDesign
import RedentKit
import SwiftUI

/// Lays out the window's panes. One pane is the ordinary case and costs exactly
/// what it did before; more appear only when the user asks for them.
struct SplitPageHost: View {
    @Bindable var model: BrowserModel
    /// The shares the panes had when the current divider drag began. A drag
    /// reports its total travel, so it is applied to where it started — adding
    /// it to the live shares every frame made the seam run away from the cursor.
    @State private var dragStart: [Double]?

    var body: some View {
        let panes = model.splitTabs
        if model.isShowingSplit, panes.count > 1 {
            GeometryReader { proxy in
                let horizontal = model.split.orientation == .horizontal
                let extent = horizontal ? proxy.size.width : proxy.size.height
                let layout = horizontal ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
                layout { paneRow(panes, along: extent) }
            }
        } else {
            PagePane(model: model, tab: model.selectedTab, pane: 0)
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func paneRow(_ tabs: [any BrowserTab], along extent: CGFloat) -> some View {
        let dividers = CGFloat(tabs.count - 1) * SplitDivider.thickness
        ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
            if index > 0 { divider(after: index - 1, extent: extent) }
            PagePane(model: model, tab: tab, pane: index)
                .frame(
                    width: isHorizontal ? size(of: index, in: extent - dividers) : nil,
                    height: isHorizontal ? nil : size(of: index, in: extent - dividers)
                )
        }
    }

    private func divider(after index: Int, extent: CGFloat) -> some View {
        SplitDivider(
            orientation: model.split.orientation,
            onDrag: { travel in
                guard extent > 0 else { return }
                let start = dragStart ?? model.split.fractions
                dragStart = start
                model.split.resize(divider: index, from: start, by: travel / extent)
            },
            onEnd: { dragStart = nil }
        )
    }

    private var isHorizontal: Bool { model.split.orientation == .horizontal }

    private func size(of index: Int, in available: CGFloat) -> CGFloat {
        let fractions = model.split.fractions
        guard fractions.indices.contains(index) else { return 0 }
        return max(available, 0) * fractions[index]
    }
}
