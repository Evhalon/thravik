import Foundation

/// Keeps a Container's session cookies across relaunches. They authenticate
/// the user, so implementations hold them as secrets, never in plain files.
public protocol SessionCookieStoring: Sendable {
    func load(container: UUID) async -> [StoredCookie]
    func save(_ cookies: [StoredCookie], container: UUID) async
    func remove(container: UUID) async
}
