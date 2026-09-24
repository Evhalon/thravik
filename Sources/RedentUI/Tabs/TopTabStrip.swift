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
                LazyHStack(spacing: 3) {
                    ForEach(model.tabs.visibleTabs, id: \.id) { tab in
                        if !model.isInSplit(tab.id) {
                            TopTabItem(
                                tab: tab,
                                isSelected: tab.id == model.tabs.selectedID,
                                namespace: selection,
                                actions: actions(for: tab),
                                drag: drag
                            )
                        } else if tab.id == model.split.tabIDs.first {
                            SplitTabRow(model: model, namespace: selection)
                                .frame(width: 120 * CGFloat(model.split.paneCount))
                        }
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
        .frame(maxWidth: .infinity)
        .background { TitlebarDragRegion() }
        .animation(.spring(duration: 0.3), value: model.tabs.selectedID)
    }

    private func actions(for tab: any BrowserTab) -> TabRowActions {
        TabRowActions(
            onSelect: { model.tabs.select(tab.id) },
            onClose: { model.tabs.close(tab.id) },
            onTogglePin: { model.tabs.togglePin(tab.id) },
            onDuplicate: tab.url == nil ? nil : { _ = model.tabs.duplicateTab(tab.id) },
            onSplit: model.canSplit(with: tab.id) ? { model.splitWith(tab.id) } : nil,
            onUnsplit: model.isInSplit(tab.id) ? { model.removeFromSplit(tab.id) } : nil,
            onCloseOthers: canCloseOthers(than: tab) ? { model.tabs.closeOthers(than: tab.id) } : nil,
            onReorder: { model.commitTabDrag(tab.id, order: $0) }
        )
    }

    private func canCloseOthers(than tab: any BrowserTab) -> Bool {
        model.tabs.visibleTabs.contains { $0.id != tab.id && !$0.isPinned }
    }
}
