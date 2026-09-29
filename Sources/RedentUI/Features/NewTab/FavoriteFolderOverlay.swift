import RedentDesign
import SwiftUI

/// A centered favorites panel whose backdrop is the explicit dismissal target.
///
/// The backdrop also takes drops: a favorite dragged out of the panel leaves
/// the folder, the same gesture as pulling an app out of a Launchpad folder.
struct FavoriteFolderOverlay: View {
    let folder: FavoriteFolder
    let tiles: [NewTabTile]
    let onOpen: (NewTabTile, Bool) -> Void
    let onRenameFavorite: (NewTabTile) -> Void
    let onRemoveFromFolder: (UUID) -> Void
    let onDeleteFolder: (FavoriteFolder) -> Void
    let onDismiss: () -> Void

    @State private var isDropTarget = false
    @State private var isPresented = false

    var body: some View {
        ZStack {
            backdrop
            FavoriteFolderSheet(
                folder: folder,
                tiles: tiles,
                onOpen: onOpen,
                onRenameFavorite: onRenameFavorite,
                onRemoveFromFolder: onRemoveFromFolder,
                onDeleteFolder: onDeleteFolder,
                onDismiss: onDismiss
            )
            .scaleEffect(isPresented ? (isDropTarget ? 0.97 : 1) : 0.9)
            .opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.34, dampingFraction: 0.78), value: isPresented)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isDropTarget)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
        .zIndex(1)
        .onExitCommand(perform: onDismiss)
        .onAppear { isPresented = true }
    }

    private var backdrop: some View {
        Color.black.opacity(isDropTarget ? 0.32 : 0.18)
            .contentShape(.rect)
            .onTapGesture(perform: onDismiss)
            .overlay(alignment: .bottom) { dropHint }
            .animation(.easeOut(duration: 0.18), value: isDropTarget)
            .dropDestination(for: String.self, action: receive) { isDropTarget = $0 }
    }

    @ViewBuilder
    private var dropHint: some View {
        if isDropTarget {
            Label("Release to move out of \(folder.name)", systemImage: "arrow.up.bin")
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: .capsule)
                .padding(.bottom, 36)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func receive(_ values: [String], at _: CGPoint) -> Bool {
        guard let value = values.first,
              let bookmarkID = UUID(uuidString: value),
              tiles.contains(where: { $0.bookmarkID == bookmarkID })
        else { return false }
        onRemoveFromFolder(bookmarkID)
        return true
    }
}
