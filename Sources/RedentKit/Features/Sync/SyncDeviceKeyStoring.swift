import Foundation

public protocol SyncDeviceKeyStoring: Sendable {
    func load(accountID: UUID) async throws -> SyncDeviceSecrets?
    func save(_ secrets: SyncDeviceSecrets, accountID: UUID) async throws
    func delete(accountID: UUID) async throws
}
