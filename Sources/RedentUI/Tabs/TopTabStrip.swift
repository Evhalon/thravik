import RedentDesign
import RedentKit
import SwiftUI

/// The familiar horizontal strip, for people who want their tabs where Chrome
/// puts them. Same pills, laid out sideways.
struct TopTabStrip: View {
    @Bindable var model: BrowserModel
    @Namespace private var selection

    /// See `SidebarTabList.dragSpace`.
    static let dragSpace = "topTabs"

    @State private var drag = TabDragCoordinator(axis: .horizontal)

    var body: some View {
        HStack(spacing: Metric.tightGutter) {
            ScrollView(.horizontal) {
                HStack(spacing: 3) {
                    ForEach(model.tabs.visibleTabs, id: \.id) { tab in
                        TopTabItem(
                            tab: tab,
                            isSelected: tab.id == model.tabs.selectedID,
                            namespace: selection,
                            actions: actions(for: tab),
                            drag: drag
                        )
                    }
                }
                .padding(.vertical, 5)
                .coordinateSpace(.named(Self.dragSpace))
            }
            .scrollIndicators(.never)

            ChromeButton(systemImage: "plus", help: "New tab", action: model.openNewTab)
        }
        .padding(.horizontal, Metric.gutter)
        .frame(height: Metric.tabRowHeight + 14)
        .animation(.spring(duration: 0.3), value: model.tabs.selectedID)
    }

    private func actions(for tab: any BrowserTab) -> TabRowActions {
        TabRowActions(
            onSelect: { model.tabs.select(tab.id) },
            onClose: { model.tabs.close(tab.id) },
            onTogglePin: { model.tabs.togglePin(tab.id) },
            onCloseOthers: canCloseOthers(than: tab) ? { model.tabs.closeOthers(than: tab.id) } : nil,
            onReorder: { model.commitTabDrag(tab.id, order: $0) }
        )
    }

    private func canCloseOthers(than tab: any BrowserTab) -> Bool {
        model.tabs.visibleTabs.contains { $0.id != tab.id && !$0.isPinned }
    }
}
