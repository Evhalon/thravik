import Foundation

public struct PasswordConflict: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let label: String

    public init(id: UUID, label: String) {
        self.id = id
        self.label = label
    }
}
