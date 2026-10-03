import RedentDesign
import RedentKit
import SwiftUI

/// A top-level folder: its pages live in the dropdown.
struct BookmarksBarFolderChip: View {
    let folder: BookmarkFolder
    let bookmarks: [Bookmark]
    let callbacks: BookmarksBarCallbacks
    @State private var isHovering = false

    private typealias Chip = BookmarksBarChipMetrics

    var body: some View {
        Menu {
            ForEach(bookmarks, id: \.id) { bookmark in
                Button(bookmark.displayTitle) { callbacks.onOpen(bookmark.url) }
            }
        } label: {
            label
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .chromeHoverEffect(isActive: isHovering, radius: Metric.smallRadius)
        .onHover { isHovering = $0 }
        .help(folder.label)
        .accessibilityLabel("\(name) folder")
        .contextMenu { BookmarksBarMenu(folder: folder, callbacks: callbacks) }
    }

    private var name: String { folder.path.last ?? folder.label }

    private var label: some View {
        HStack(spacing: Chip.iconSpacing) {
            Image(systemName: "folder")
                .font(.system(size: Chip.folderGlyphSize, weight: .semibold))
                .foregroundStyle(Palette.chromeSecondaryText)
            Text(name)
                .font(.system(size: Chip.titleSize))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: Chip.chevronSize, weight: .bold))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .padding(.horizontal, Chip.horizontalPadding)
        .padding(.vertical, Chip.verticalPadding)
        .frame(maxWidth: Chip.maxWidth)
        .contentShape(.rect)
    }
}
