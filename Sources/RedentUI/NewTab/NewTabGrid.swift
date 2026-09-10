import RedentDesign
import SwiftUI

/// The new-tab collections: loose favorites, folders, and frequent pages.
struct NewTabGrid: View {
    let favorites: [NewTabTile]
    let folders: [FavoriteFolder]
    let frequent: [NewTabTile]
    let tilesForFolder: (FavoriteFolder) -> [NewTabTile]
    let onOpen: (NewTabTile, Bool) -> Void
    let onCreateFolder: () -> Void
    let onMoveFavorite: (UUID, FavoriteFolder) -> Void
    let onRemoveFavorite: (UUID) -> Void
    let onDeleteFolder: (FavoriteFolder) -> Void

    @State private var openedFolder: FavoriteFolder?

    private let columns = [GridItem(.adaptive(minimum: 96, maximum: 96), spacing: 18)]

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            if !favorites.isEmpty || !folders.isEmpty { favoritesSection }
            if !frequent.isEmpty { tileSection(title: "FREQUENTLY VISITED", tiles: frequent) }
        }
        .padding(.horizontal, 52)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $openedFolder) { folder in
            FavoriteFolderSheet(
                folder: folder,
                tiles: tilesForFolder(folder),
                onOpen: onOpen,
                onRemoveFavorite: onRemoveFavorite,
                onDeleteFolder: onDeleteFolder
            )
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: Metric.gutter + 2) {
            HStack(spacing: Metric.tightGutter) {
                sectionTitle("FAVORITES")
                Spacer()
                Button(action: onCreateFolder) {
                    Label("New folder", systemImage: "folder.badge.plus")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.chromeSecondaryText)
                .help("Create a favorites folder")
            }
            LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
                ForEach(folders) { folder in
                    FavoriteFolderTile(
                        folder: folder,
                        onOpen: { openedFolder = folder },
                        onPrepare: { prefetchIcons(for: folder) },
                        onReceiveFavorite: { onMoveFavorite($0, folder) }
                    )
                }
                ForEach(favorites) { tile in
                    NewTabTileView(tile: tile) { onOpen(tile, $0) }
                }
            }
        }
    }

    private func tileSection(title: String, tiles: [NewTabTile]) -> some View {
        VStack(alignment: .leading, spacing: Metric.gutter + 2) {
            sectionTitle(title)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
                ForEach(tiles) { tile in
                    NewTabTileView(tile: tile) { onOpen(tile, $0) }
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9.5, weight: .bold))
            .tracking(1.1)
            .foregroundStyle(Palette.chromeSecondaryText)
            .padding(.leading, 4)
    }

    private func prefetchIcons(for folder: FavoriteFolder) {
        let hosts = tilesForFolder(folder)
            .filter { $0.faviconData == nil }
            .map(\.host)
        Task { await SiteIconLoader.shared.preload(hosts: hosts) }
    }
}
