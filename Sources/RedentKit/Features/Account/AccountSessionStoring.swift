import Foundation

public protocol AccountSessionStoring: Sendable {
    func load() async throws -> AccountSession?
    func save(_ session: AccountSession) async throws
    func clear() async throws
}
