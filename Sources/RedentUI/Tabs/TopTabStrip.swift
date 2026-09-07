import RedentDesign
import SwiftUI

/// The familiar horizontal strip, for people who want their tabs where Chrome
/// puts them. Same pills, laid out sideways.
struct TopTabStrip: View {
    @Bindable var model: BrowserModel
    @Namespace private var selection

    var body: some View {
        HStack(spacing: Metric.tightGutter) {
            ScrollView(.horizontal) {
                HStack(spacing: 3) {
                    ForEach(model.tabs.visibleTabs, id: \.id) { tab in
                        TopTabItem(
                            tab: tab,
                            isSelected: tab.id == model.tabs.selectedID,
                            namespace: selection,
                            onSelect: { model.tabs.select(tab.id) },
                            onClose: { model.tabs.close(tab.id) },
                            onTogglePin: { model.tabs.togglePin(tab.id) }
                        )
                    }
                }
                .padding(.vertical, 5)
            }
            .scrollIndicators(.never)

            ChromeButton(systemImage: "plus", help: "New tab", action: model.openNewTab)
        }
        .padding(.horizontal, Metric.gutter)
        .frame(height: Metric.tabRowHeight + 14)
        .animation(.spring(duration: 0.3), value: model.tabs.selectedID)
    }
}
