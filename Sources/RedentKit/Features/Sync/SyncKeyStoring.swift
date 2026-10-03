import Foundation

public protocol SyncKeyStoring: Sendable {
    func load(accountID: UUID) async throws -> Data?
    func save(_ key: Data, accountID: UUID) async throws
    func delete(accountID: UUID) async throws
}
