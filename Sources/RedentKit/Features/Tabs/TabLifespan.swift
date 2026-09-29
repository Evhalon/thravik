import Foundation

public enum TabLifespan: Codable, Sendable, Hashable {
    case normal
    case temporary(sessionID: UUID, expiresAt: Date?, cleanupOnClose: Bool)

    public var expiresAt: Date? {
        guard case let .temporary(_, expiry, _) = self else { return nil }
        return expiry
    }

    public var isTemporary: Bool {
        if case .temporary = self { return true }
        return false
    }
}
