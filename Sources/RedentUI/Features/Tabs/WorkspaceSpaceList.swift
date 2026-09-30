import RedentDesign
import RedentKit
import SwiftUI

/// The Spaces in their sidebar order. Dragging a row reorders them — the
/// orbs, the menu and the ⌃⌥ number shortcuts all follow this order.
struct WorkspaceSpaceList: View {
    let model: BrowserModel
    let onSelect: (BrowserSpace) -> Void
    let onCustomize: (BrowserSpace) -> Void

    var body: some View {
        List {
            ForEach(spaces) { space in
                WorkspaceSpaceRow(
                    space: space,
                    tabCount: tabCount(space.id),
                    isSelected: space.id == model.tabs.session.selectedSpaceID,
                    actions: actions(for: space)
                )
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onMove(perform: move)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.never)
    }

    private var spaces: [BrowserSpace] { model.tabs.session.spaces }

    private func move(from source: IndexSet, to destination: Int) {
        guard let action = SpaceReorder.action(spaces: spaces, from: source, to: destination) else { return }
        withAnimation(.spring(duration: 0.3)) { model.execute(action) }
    }

    private func actions(for space: BrowserSpace) -> WorkspaceSpaceRow.Actions {
        WorkspaceSpaceRow.Actions(
            canDelete: spaces.count > 1,
            onSelect: { onSelect(space) },
            onCustomize: { onCustomize(space) },
            onDelete: { model.execute(.deleteSpace(space.id)) }
        )
    }

    private func tabCount(_ id: UUID) -> Int {
        model.tabs.tabs.filter { $0.snapshot.spaceID == id }.count
    }
}
