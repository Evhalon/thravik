import RedentDesign
import RedentKit
import SwiftUI

/// Horizontal chips for the current Space, with a trailing overflow menu.
struct BookmarksBar: View {
    @Bindable var model: BrowserModel
    @State private var bar: BookmarksBarModel
    @State private var availableWidth: CGFloat = 0
    @State private var editor: BookmarkEditor.Mode?
    @State private var pendingFolderDeletion: BookmarkFolder?
    @State private var revision = 0

    init(model: BrowserModel) {
        self.model = model
        _bar = State(initialValue: BookmarksBarModel(store: model.bookmarks))
    }

    var body: some View {
        chips
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { availableWidth = $0 }
            .padding(.horizontal, Metric.tightGutter + 2)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) { Palette.hairline.frame(height: Metric.hairWidth) }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Bookmarks bar")
            .task(id: ReloadKey(spaceID: model.currentSpaceID, revision: revision)) { await reload() }
            .onReceive(NotificationCenter.default.publisher(for: .bookmarksDidChange)) { _ in revision &+= 1 }
            .sheet(item: $editor) { mode in BookmarkEditor(mode: mode, onSave: save) }
            .confirmationDialog(
                deletionTitle, isPresented: isConfirmingDeletion, titleVisibility: .visible,
                presenting: pendingFolderDeletion
            ) { folder in
                Button("Delete Folder", role: .destructive) { delete(folder) }
            } message: { _ in
                Text("Every bookmark inside it is deleted too.")
            }
            .preference(key: ChromePresentationLockKey.self, value: editor != nil || pendingFolderDeletion != nil)
    }

    private var chips: some View {
        HStack(spacing: BookmarksBarOverflow.spacing) {
            ForEach(visibleItems, id: \.id) { item in chip(item) }
            if plan.hasOverflow {
                BookmarksBarOverflowMenu(items: overflowItems, callbacks: callbacks)
            }
            Spacer(minLength: 0)
        }
    }

    private var plan: BookmarksBarOverflow.Plan {
        BookmarksBarOverflow.plan(
            itemWidths: bar.itemWidths,
            availableWidth: Double(availableWidth),
            overflowWidth: BookmarksBarOverflow.overflowButtonWidth,
            spacing: BookmarksBarOverflow.spacing
        )
    }

    private var visibleItems: [BookmarksBarItem] { Array(bar.items.prefix(plan.visibleCount)) }
    private var overflowItems: [BookmarksBarItem] { Array(bar.items.dropFirst(plan.visibleCount)) }

    @ViewBuilder
    private func chip(_ item: BookmarksBarItem) -> some View {
        switch item {
        case .page(let bookmark):
            BookmarksBarChip(bookmark: bookmark, callbacks: callbacks)
        case .folder(let folder, let bookmarks):
            BookmarksBarFolderChip(folder: folder, bookmarks: bookmarks, callbacks: callbacks)
        }
    }

    private var callbacks: BookmarksBarCallbacks {
        BookmarksBarCallbacks(
            onOpen: { model.openBookmarksBarURL($0) },
            onOpenNewTab: { model.openBookmark($0, target: .backgroundTab) },
            onEdit: { editor = .edit($0) },
            onDelete: { bookmark in Task { await bar.delete(bookmark) } },
            onDeleteFolder: { pendingFolderDeletion = $0 }
        )
    }

    /// Writes arrive in bursts (a folder delete is one per page); the restarted
    /// task coalesces them into one read.
    private func reload() async {
        if revision > 0 {
            do { try await Task.sleep(for: .milliseconds(60)) } catch { return }
        }
        await bar.load(in: model.currentSpaceID)
        await model.refreshBookmarkState()
    }

    private func delete(_ folder: BookmarkFolder) {
        pendingFolderDeletion = nil
        Task { await bar.deleteFolder(folder) }
    }

    private func save(_ mode: BookmarkEditor.Mode, title: String, address: String) async -> Bool {
        guard case .edit(let bookmark) = mode else { return false }
        return await bar.update(bookmark, title: title, address: address)
    }

    private var deletionTitle: String {
        "Delete “\(pendingFolderDeletion.map { $0.path.last ?? $0.label } ?? "")”?"
    }

    private var isConfirmingDeletion: Binding<Bool> {
        Binding(get: { pendingFolderDeletion != nil }, set: { if !$0 { pendingFolderDeletion = nil } })
    }
}

private struct ReloadKey: Hashable {
    let spaceID: UUID?
    let revision: Int
}
