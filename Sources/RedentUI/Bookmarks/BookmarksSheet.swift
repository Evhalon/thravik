import AppKit
import RedentDesign
import SwiftUI

/// The bookmarks manager: folders on the left, entries on the right.
public struct BookmarksSheet: View {
    @State private var model: BookmarksModel
    @State private var editor: BookmarkEditor.Mode?
    private let onOpen: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(model: BookmarksModel, onOpen: @escaping (URL) -> Void) {
        _model = State(initialValue: model)
        self.onOpen = onOpen
    }

    public var body: some View {
        VStack(spacing: 0) {
            header.padding(Metric.gutter)

            Divider()

            HSplitView {
                folderList.frame(minWidth: 160, idealWidth: 180)
                entryList.frame(minWidth: 320)
            }
            .padding(Metric.gutter)
        }
        .frame(minWidth: 640, minHeight: 420)
        .sheetCanvas(width: 720, height: 520)
        .task { await model.load() }
        .sheet(item: $editor) { mode in
            BookmarkEditor(mode: mode, onSave: save)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Bookmarks").font(.system(size: 15, weight: .semibold))
                Text(model.showsEverySpace ? "Every Space" : model.currentSpaceName)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            Spacer()
            Toggle("All Spaces", isOn: $model.showsEverySpace)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .font(.system(size: 11))
            TextField("Search", text: $model.query)
                .textFieldStyle(.roundedBorder)
                .frame(width: 170)
            Button("Done") { dismiss() }
        }
    }

    private var folderList: some View {
        List(selection: $model.selectedFolder) {
            Text("All Bookmarks").tag(String?.none)
            ForEach(model.folders, id: \.self) { folder in
                Label(folder, systemImage: "folder").tag(String?.some(folder))
            }
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private var entryList: some View {
        if model.visible.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "star").font(.system(size: 26, weight: .light))
                Text(model.showsEverySpace
                     ? "No bookmarks yet"
                     : "Nothing saved in \(model.currentSpaceName) yet")
                    .font(.system(size: 12))
            }
            .foregroundStyle(Palette.chromeSecondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(model.visible) { bookmark in
                BookmarkRow(
                    bookmark: bookmark,
                    spaceName: model.showsEverySpace ? model.name(ofSpace: bookmark.spaceID) : nil,
                    spaces: model.spaces,
                    actions: .init(
                        onOpen: { onOpen(bookmark.url); dismiss() },
                        onToggleFavorite: { Task { await model.toggleFavorite(bookmark) } },
                        onMove: { destination in Task { await model.move(bookmark, to: destination) } },
                        onRename: { editor = .rename(bookmark) },
                        onEditAddress: { editor = .address(bookmark) },
                        onCopyAddress: { copyAddress(bookmark.url) },
                        onDelete: { Task { await model.delete(bookmark) } }
                    )
                )
            }
            .listStyle(.inset)
        }
    }

    private func save(_ mode: BookmarkEditor.Mode, value: String) async -> Bool {
        switch mode {
        case .rename(let bookmark):
            return await model.rename(bookmark, to: value)
        case .address(let bookmark):
            return await model.changeAddress(bookmark, to: value)
        }
    }

    private func copyAddress(_ url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.absoluteString, forType: .string)
    }
}
