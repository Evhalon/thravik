import RedentDesign
import SwiftUI

/// What follows the pointer while a favorite is dragged.
///
/// The system snapshots the preview at its own bounds, so the padding leaves
/// room for the badge and the lifted shadow instead of cropping them. No
/// materials: they render as flat grey in a drag image.
struct FavoriteDragPreview: View {
    let tile: NewTabTile
    let iconData: Data?
    let accent: Color

    var body: some View {
        VStack(spacing: 8) {
            FavoriteTileIcon(
                host: tile.host,
                iconData: iconData,
                accent: accent,
                isFavorite: tile.isFavorite,
                isLifted: true
            )
            .rotationEffect(.degrees(-3))
            Text(tile.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.55)))
                .frame(maxWidth: 120)
        }
        .padding(22)
    }
}
