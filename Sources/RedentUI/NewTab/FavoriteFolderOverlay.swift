import SwiftUI

/// A centered favorites panel whose backdrop is the explicit dismissal target.
struct FavoriteFolderOverlay: View {
    let folder: FavoriteFolder
    let tiles: [NewTabTile]
    let onOpen: (NewTabTile, Bool) -> Void
    let onRenameFavorite: (NewTabTile) -> Void
    let onRemoveFromFolder: (UUID) -> Void
    let onDeleteFolder: (FavoriteFolder) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .contentShape(.rect)
                .onTapGesture(perform: onDismiss)
            FavoriteFolderSheet(
                folder: folder,
                tiles: tiles,
                onOpen: onOpen,
                onRenameFavorite: onRenameFavorite,
                onRemoveFromFolder: onRemoveFromFolder,
                onDeleteFolder: onDeleteFolder,
                onDismiss: onDismiss
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
        .zIndex(1)
        .onExitCommand(perform: onDismiss)
    }
}
