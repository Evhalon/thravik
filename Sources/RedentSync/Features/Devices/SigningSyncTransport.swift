import Foundation
import RedentKit

public protocol SyncPushAuthenticating: SyncTransporting {
    func push(_ mutation: SyncMutation, proof: SyncDeviceProof, session: AccountSession) async throws -> SyncRemoteRecord
}

public struct SigningSyncTransport: SyncTransporting {
    private let inner: any SyncPushAuthenticating
    private let keys: any SyncDeviceKeyStoring
    private let directory: any SyncDeviceDirectorying
    private let accountID: UUID

    public init(inner: some SyncPushAuthenticating, keys: any SyncDeviceKeyStoring,
                directory: any SyncDeviceDirectorying, accountID: UUID) {
        self.inner = inner
        self.keys = keys
        self.directory = directory
        self.accountID = accountID
    }

    public func push(_ mutation: SyncMutation, session: AccountSession) async throws -> SyncRemoteRecord {
        guard session.accountID == accountID, mutation.identity.accountID == accountID else {
            throw SyncError.accountMismatch
        }
        guard let secrets = try await keys.load(accountID: accountID) else {
            return try await inner.push(mutation, session: session)
        }
        return try await inner.push(mutation, proof: try SyncDeviceSigner().proof(for: mutation, secrets: secrets),
                                    session: session)
    }

    public func pull(after cursor: Int64, session: AccountSession) async throws -> SyncPage {
        guard session.accountID == accountID else { throw SyncError.accountMismatch }
        let page = try await inner.pull(after: cursor, session: session)
        guard try await keys.load(accountID: accountID) != nil else { return page }
        let devices = try await directory.list(session: session)
        guard devices.contains(where: { $0.status == .approved }) else { return page }
        try SyncDevicePageVerifier().verify(page, devices: devices)
        return page
    }
}
