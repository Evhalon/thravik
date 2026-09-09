import Foundation

/// A user-created bookmark folder, including folders with no pages yet.
public struct BookmarkFolder: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var path: [String]
    public var spaceID: UUID?

    public init(id: UUID = UUID(), path: [String], spaceID: UUID?) {
        self.id = id
        self.path = path
        self.spaceID = spaceID
    }

    public var label: String { path.joined(separator: " / ") }
}
