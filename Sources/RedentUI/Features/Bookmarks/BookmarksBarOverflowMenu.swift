import RedentDesign
import RedentKit
import SwiftUI

/// Pages and folders that did not fit on the bar.
struct BookmarksBarOverflowMenu: View {
    let items: [BookmarksBarItem]
    let callbacks: BookmarksBarCallbacks
    @State private var isHovering = false

    var body: some View {
        Menu {
            ForEach(items, id: \.id) { item in
                switch item {
                case .page(let bookmark):
                    Button(bookmark.displayTitle) { callbacks.onOpen(bookmark.url) }
                case .folder(let folder, let bookmarks):
                    Menu(folder.path.last ?? folder.label) {
                        ForEach(bookmarks, id: \.id) { bookmark in
                            Button(bookmark.displayTitle) { callbacks.onOpen(bookmark.url) }
                        }
                    }
                }
            }
        } label: {
            Text("»")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.chromeText)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .contentShape(.rect)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .chromeHoverEffect(isActive: isHovering, radius: Metric.smallRadius)
        .onHover { isHovering = $0 }
        .help("More bookmarks")
        .accessibilityLabel("More bookmarks")
    }
}
