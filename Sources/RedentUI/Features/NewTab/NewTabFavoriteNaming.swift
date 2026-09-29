import Foundation

extension NewTabModel {
    @discardableResult
    public func renameFavorite(_ tile: NewTabTile, to name: String) async -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let id = tile.bookmarkID, !name.isEmpty,
              let bookmark = favorites.first(where: { $0.id == id })
        else { return false }
        var updated = bookmark
        updated.title = name
        await bookmarks.save(updated)
        await load(in: spaceID)
        return true
    }
}
