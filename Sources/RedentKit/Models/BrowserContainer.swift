import Foundation

public enum ContainerKind: String, Codable, Sendable, Hashable {
    case `default`
    case named
    case ephemeral
}

public struct BrowserContainer: Identifiable, Codable, Sendable, Hashable {
    public static let defaultID = UUID(uuid: (0x45, 0x44, 0x43, 0x01, 0x00, 0x00, 0x00, 0x00,
                                               0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01))
    public static let `default` = BrowserContainer(id: defaultID, name: "Default", kind: .default)

    public let id: UUID
    public var name: String
    public var kind: ContainerKind

    /// The Container's own id doubles as its WebKit profile identifier, so the
    /// store and the model can never drift apart.
    public init(id: UUID = UUID(), name: String, kind: ContainerKind = .named) {
        self.id = id
        self.name = name
        self.kind = kind
    }
}
