import RedentDesign
import RedentKit
import SwiftUI

/// One saved page in the manager.
struct BookmarkRow: View {
    let bookmark: Bookmark
    let onOpen: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Metric.gutter - 2) {
            FaviconView(data: bookmark.faviconData, host: bookmark.origin?.displayHost, size: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(bookmark.displayTitle).font(.system(size: 12.5)).lineLimit(1)
                Text(bookmark.origin?.displayHost ?? bookmark.url.absoluteString)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: Metric.gutter)

            Button(action: onToggleFavorite) {
                Image(systemName: bookmark.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(bookmark.isFavorite ? Palette.accent : Palette.chromeSecondaryText)
            }
            .buttonStyle(.plain)
            .help(bookmark.isFavorite ? "Remove from new-tab favorites" : "Show on the new-tab page")

            Button(action: onDelete) {
                Image(systemName: "trash").foregroundStyle(Palette.chromeSecondaryText)
            }
            .buttonStyle(.plain)
            .help("Delete bookmark")
        }
        .padding(.vertical, 3)
        .contentShape(.rect)
        .onTapGesture(count: 2, perform: onOpen)
    }
}
