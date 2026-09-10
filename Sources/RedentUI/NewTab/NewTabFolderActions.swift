import Foundation
import RedentKit

extension NewTabModel {
    @discardableResult
    public func createFavoriteFolder(named name: String) async -> Bool {
        let label = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty,
              !label.contains("/"),
              !favoriteFolders.contains(where: { $0.path == [label] })
        else { return false }
        await bookmarks.saveFolder(BookmarkFolder(path: [label], spaceID: spaceID))
        await load(in: spaceID)
        return true
    }

    public func moveFavorite(_ id: UUID, into folder: FavoriteFolder) async {
        await updateFavorite(id, folderPath: folder.path)
    }

    public func removeFavoriteFromFolder(_ id: UUID) async {
        await updateFavorite(id, folderPath: [])
    }

    public func deleteFavoriteFolder(_ folder: FavoriteFolder) async {
        for bookmark in favorites where bookmark.folderPath == folder.path {
            var moved = bookmark
            moved.folderPath = []
            await bookmarks.save(moved)
        }
        await bookmarks.deleteFolder(BookmarkFolder(path: folder.path, spaceID: spaceID))
        await load(in: spaceID)
    }

    private func updateFavorite(_ id: UUID, folderPath: [String]) async {
        guard let bookmark = favorites.first(where: { $0.id == id }), bookmark.folderPath != folderPath
        else { return }
        var updated = bookmark
        updated.folderPath = folderPath
        await bookmarks.save(updated)
        await load(in: spaceID)
    }
}
