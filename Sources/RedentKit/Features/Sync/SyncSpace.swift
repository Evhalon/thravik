import Foundation

public struct SyncSpace: Codable, Sendable, Equatable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var colorToken: String
    public var order: Int

    public init(id: UUID, name: String, icon: String, colorToken: String, order: Int) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorToken = colorToken
        self.order = order
    }
}
