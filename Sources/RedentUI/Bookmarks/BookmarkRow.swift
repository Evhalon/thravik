import RedentDesign
import RedentKit
import SwiftUI

/// One saved page in the manager.
struct BookmarkRow: View {
    let bookmark: Bookmark
    /// Shown only while the manager is listing every Space at once.
    let spaceName: String?
    let spaces: [BrowserSpace]
    let actions: Actions

    struct Actions {
        let onOpen: () -> Void
        let onToggleFavorite: () -> Void
        let onMove: (UUID) -> Void
        let onDelete: () -> Void
    }

    var body: some View {
        HStack(spacing: Metric.gutter - 2) {
            FaviconView(data: bookmark.faviconData, host: bookmark.origin?.displayHost, size: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(bookmark.displayTitle).font(.system(size: 12.5)).lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: Metric.gutter)

            Button(action: actions.onToggleFavorite) {
                Image(systemName: bookmark.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(bookmark.isFavorite ? Palette.accent : Palette.chromeSecondaryText)
            }
            .buttonStyle(.plain)
            .help(bookmark.isFavorite ? "Remove from new-tab favorites" : "Show on the new-tab page")

            Button(action: actions.onDelete) {
                Image(systemName: "trash").foregroundStyle(Palette.chromeSecondaryText)
            }
            .buttonStyle(.plain)
            .help("Delete bookmark")
        }
        .padding(.vertical, 3)
        .contentShape(.rect)
        .onTapGesture(count: 2, perform: actions.onOpen)
        .contextMenu {
            Button("Open", action: actions.onOpen)
            Menu("Move to Space") {
                ForEach(spaces) { space in
                    Button(space.name) { actions.onMove(space.id) }
                        .disabled(space.id == bookmark.spaceID)
                }
            }
            Divider()
            Button("Delete", role: .destructive, action: actions.onDelete)
        }
    }

    private var host: String {
        bookmark.origin?.displayHost ?? bookmark.url.absoluteString
    }

    private var subtitle: String {
        guard let spaceName else { return host }
        return "\(host) · \(spaceName)"
    }
}
