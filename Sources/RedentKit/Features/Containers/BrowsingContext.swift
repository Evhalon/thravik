import Foundation

/// The website-data boundary a tab browses in.
///
/// The domain names the boundary and nothing more: only the engine knows a
/// context resolves to a WebKit data store. Two tabs sharing a context share
/// cookies and storage; two tabs in different contexts cannot see each other's.
public enum BrowsingContext: Hashable, Sendable, Codable {
    /// Cookies and storage that survive relaunch, keyed by Container.
    case container(UUID)
    /// An in-memory store discarded once its last tab is gone.
    case ephemeral(UUID)

    public var containerID: UUID? {
        guard case let .container(id) = self else { return nil }
        return id
    }

    public var isEphemeral: Bool {
        if case .ephemeral = self { return true }
        return false
    }
}
