import AppKit
import RedentDesign
import SwiftUI

/// One site in the new-tab grid.
///
/// The tile takes its color from the site's own favicon, so the grid reads as a
/// set of places rather than a list of links — recognisable at a glance, before
/// any label is read.
struct NewTabTileView: View {
    let tile: NewTabTile
    let onOpen: (_ commandHeld: Bool) -> Void
    var onRemoveFavorite: (() -> Void)?
    var onRenameFavorite: (() -> Void)?
    var onRemoveFromFolder: (() -> Void)?

    @State private var isHovering = false
    @State private var artwork: TileArtwork?

    var body: some View {
        Button(action: { onOpen(NSEvent.modifierFlags.contains(.command)) }) {
            VStack(spacing: 9) {
                icon
                Text(tile.isFavorite ? tile.title : tile.host)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .lineLimit(1)
            }
            .frame(width: 96)
            .contentShape(.rect)
        }
        .buttonStyle(PressScaleStyle())
        .scaleEffect(isHovering ? 1.06 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isHovering)
        .onHover { isHovering = $0 }
        .help(tile.title)
        .contextMenu { menu }
        .modifier(FavoriteTileDragModifier(tile: tile, artwork: resolvedArtwork))
        .task(id: tile) { artwork = await TileArtwork.resolve(for: tile) }
    }

    @ViewBuilder
    private var menu: some View {
        if let onRenameFavorite {
            Button("Rename Favorite…", action: onRenameFavorite)
        }
        if let onRemoveFromFolder {
            Button("Remove from Folder", action: onRemoveFromFolder)
        }
        if tile.isFavorite, let onRemoveFavorite {
            Button("Remove from Favorites", role: .destructive, action: onRemoveFavorite)
        }
    }

    /// Decoding and color sampling happen once per tile, not on every hover frame.
    private var resolvedArtwork: TileArtwork {
        artwork ?? TileArtwork(iconData: nil, accent: TileArtwork.fallbackAccent(for: tile.host))
    }

    private var icon: some View {
        FavoriteTileIcon(
            host: tile.host,
            iconData: resolvedArtwork.iconData,
            accent: resolvedArtwork.accent,
            isFavorite: tile.isFavorite,
            isLifted: isHovering
        )
    }
}

private struct FavoriteTileDragModifier: ViewModifier {
    let tile: NewTabTile
    let artwork: TileArtwork

    @ViewBuilder
    func body(content: Content) -> some View {
        if let bookmarkID = tile.bookmarkID {
            content.draggable(bookmarkID.uuidString) {
                FavoriteDragPreview(tile: tile, iconData: artwork.iconData, accent: artwork.accent)
            }
        } else {
            content
        }
    }
}
