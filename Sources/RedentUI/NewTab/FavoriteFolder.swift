import RedentKit

/// A saved folder rendered on the new-tab favorites surface.
public struct FavoriteFolder: Identifiable, Hashable {
    public let path: [String]
    public let favoriteCount: Int

    public init(path: [String], favoriteCount: Int = 0) {
        self.path = path
        self.favoriteCount = favoriteCount
    }

    public var id: String { path.joined(separator: "/") }
    public var name: String { path.last ?? "Favorites" }
}
