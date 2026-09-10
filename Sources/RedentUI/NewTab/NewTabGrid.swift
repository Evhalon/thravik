import RedentDesign
import SwiftUI

/// The grid of places, with a heading that names what it is.
struct NewTabGrid: View {
    let tiles: [NewTabTile]
    let onOpen: (NewTabTile, Bool) -> Void
    var onRemoveFavorite: (NewTabTile) -> Void = { _ in }

    private let columns = [GridItem(.adaptive(minimum: 96, maximum: 96), spacing: 18)]

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.gutter + 2) {
            Text(tiles.contains(where: \.isFavorite) ? "FAVORITES" : "FREQUENTLY VISITED")
                .font(.system(size: 9.5, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(Palette.chromeSecondaryText)
                .padding(.leading, 4)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
                ForEach(tiles) { tile in
                    NewTabTileView(
                        tile: tile,
                        onOpen: { onOpen(tile, $0) },
                        onRemoveFavorite: tile.isFavorite ? { onRemoveFavorite(tile) } : nil
                    )
                }
            }
        }
        // Matches the search field's own inset so the grid's left edge lines up
        // with it rather than floating free of the column above.
        .padding(.horizontal, 52)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
