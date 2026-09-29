import RedentDesign
import RedentKit
import SwiftUI

/// One saved page in the manager.
struct BookmarkRow: View {
    let bookmark: Bookmark
    /// Shown only while the manager is listing every Space at once.
    let spaceName: String?
    let actions: Actions
    @State private var showsActions = false

    struct Actions {
        let onOpen: () -> Void
        let onOpenNewTab: () -> Void
        let onOpenNewWindow: () -> Void
        let onToggleFavorite: () -> Void
        let onRename: () -> Void
        let onEditAddress: () -> Void
        let onCopyAddress: () -> Void
        let onDelete: () -> Void
        let onNewFolder: () -> Void
    }

    var body: some View {
        HStack(spacing: Metric.gutter - 2) {
            FaviconView(data: bookmark.faviconData, host: bookmark.origin?.displayHost, size: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(bookmark.displayTitle).font(.system(size: 12.5)).lineLimit(1)
                Text(address)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .lineLimit(1)
                if let spaceName {
                    Text(spaceName)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Palette.chromeSecondaryText)
                }
            }

            Spacer(minLength: Metric.gutter)

            Button(action: actions.onToggleFavorite) {
                Image(systemName: bookmark.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(bookmark.isFavorite ? Palette.accent : Palette.chromeSecondaryText)
            }
            .buttonStyle(.plain)
            .help(bookmark.isFavorite ? "Remove from new-tab favorites" : "Show on the new-tab page")

            Menu {
                rowMenu
            } label: {
                Image(systemName: "ellipsis").foregroundStyle(Palette.chromeSecondaryText)
            }
            .menuStyle(.borderlessButton)
            .help("Bookmark actions")
        }
        .padding(.vertical, 3)
        .contentShape(.rect)
        .onTapGesture { showsActions = true }
        .onTapGesture(count: 2, perform: actions.onOpen)
        .contextMenu {
            rowMenu
        }
        .popover(isPresented: $showsActions, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 0) { rowMenu }
                .padding(6)
                .frame(width: 210)
        }
    }

    @ViewBuilder
    private var rowMenu: some View {
        Button("Open in New Tab", action: actions.onOpenNewTab)
        Button("Open in New Window", action: actions.onOpenNewWindow)
        Divider()
        Button("Rename…", action: actions.onRename)
        Button("Edit Address…", action: actions.onEditAddress)
        Divider()
        Button("Copy Address", action: actions.onCopyAddress)
        Button("Delete", role: .destructive, action: actions.onDelete)
        Divider()
        Button("New Folder", action: actions.onNewFolder)
    }

    private var host: String {
        bookmark.origin?.displayHost ?? bookmark.url.absoluteString
    }

    private var address: String {
        let url = bookmark.url.absoluteString
        return url.isEmpty ? host : url
    }
}
