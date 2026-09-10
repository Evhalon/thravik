import RedentDesign
import SwiftUI

/// Shows the pages in one favorites collection without leaving the new tab.
struct FavoriteFolderSheet: View {
    let folder: FavoriteFolder
    let tiles: [NewTabTile]
    let onOpen: (NewTabTile, Bool) -> Void
    let onRemoveFavorite: (UUID) -> Void
    let onDeleteFolder: (FavoriteFolder) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmsDeletion = false

    private let columns = [GridItem(.adaptive(minimum: 96, maximum: 96), spacing: 18)]

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.gutter + 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.name).font(.system(size: 16, weight: .semibold))
                    Text("\(folder.favoriteCount) favorite\(folder.favoriteCount == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.chromeSecondaryText)
                }
                Spacer()
                Button(role: .destructive) { confirmsDeletion = true } label: {
                    Image(systemName: "trash")
                }
                .help("Delete folder")
                Button("Done") { dismiss() }
            }
            Divider()
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
                    ForEach(tiles) { tile in
                        NewTabTileView(tile: tile) { commandHeld in
                            onOpen(tile, commandHeld)
                            dismiss()
                        }
                        .contextMenu { removeFromFolderAction(for: tile) }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .frame(width: 520, height: 390, alignment: .topLeading)
        .sheetCanvas(width: 520, height: 390)
        .confirmationDialog("Delete \(folder.name)?", isPresented: $confirmsDeletion) {
            Button("Delete Folder", role: .destructive) {
                onDeleteFolder(folder)
                dismiss()
            }
        } message: {
            Text("Favorites in this folder will be moved to Favorites.")
        }
    }

    @ViewBuilder
    private func removeFromFolderAction(for tile: NewTabTile) -> some View {
        if let bookmarkID = tile.bookmarkID {
            Button("Remove from Folder") {
                onRemoveFavorite(bookmarkID)
                dismiss()
            }
        }
    }
}
