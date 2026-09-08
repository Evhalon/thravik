import Foundation
import RedentKit
import SwiftUI

/// Makes a tab row draggable and, when the row accepts drops, a reorder target.
///
/// The payload is the tab's own id: text dragged out of a page lands here too,
/// and anything that is not one of our tabs is refused.
private struct TabDragging: ViewModifier {
    let tab: any BrowserTab
    let actions: TabRowActions
    @Binding var isTargeted: Bool

    func body(content: Content) -> some View {
        content
            .draggable(tab.id.uuidString) {
                TabRowLabel(tab: tab, isSelected: false)
                    .padding(6)
            }
            .dropDestination(for: String.self) { items, _ in
                guard let onDropTab = actions.onDropTab,
                      let id = items.compactMap({ UUID(uuidString: $0) }).first else { return false }
                onDropTab(id)
                return true
            } isTargeted: { targeting in
                isTargeted = targeting && actions.onDropTab != nil
            }
    }
}

extension View {
    func tabDragging(
        tab: any BrowserTab,
        actions: TabRowActions,
        isTargeted: Binding<Bool>
    ) -> some View {
        modifier(TabDragging(tab: tab, actions: actions, isTargeted: isTargeted))
    }
}
