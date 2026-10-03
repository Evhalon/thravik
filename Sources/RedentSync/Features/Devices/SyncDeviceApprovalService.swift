import Foundation
import RedentKit

struct SyncDeviceApprovalService: Sendable {
    let rootKeys: any SyncKeyStoring
    let directory: any SyncDeviceDirectorying
    private let wrapping = SyncDeviceRootKeyWrap()

    func approve(recipientID: UUID, secrets: SyncDeviceSecrets, session: AccountSession) async throws {
        guard secrets.deviceID != recipientID else { throw SyncError.deviceRejected }
        let recipient = try await pendingRecipient(recipientID, session: session)
        guard var root = try await rootKeys.load(accountID: session.accountID), root.count == 32 else {
            throw SyncError.unauthorized
        }
        defer { root.resetBytes(in: 0..<root.count) }
        let expiry = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 + 900).rounded(.down))
        let request = SyncDeviceRootKeyWrap.Request(accountID: session.accountID, rootKey: root, sender: secrets,
                                                    recipient: recipient, requestID: UUID(), expiresAt: expiry,
                                                    keyEpoch: 1)
        try await directory.approve(try wrapping.seal(request), credential: secrets.credential, session: session)
    }

    func importRoot(secrets: SyncDeviceSecrets, session: AccountSession) async throws {
        guard let approval = try await directory.envelope(deviceID: secrets.deviceID, credential: secrets.credential,
                                                          session: session) else { throw SyncError.deviceRejected }
        let devices = try await directory.list(session: session)
        guard let sender = devices.first(where: { $0.id == approval.senderDeviceID }), sender.status == .approved
        else { throw SyncError.deviceRejected }
        let root = try wrapping.open(approval, accountID: session.accountID, recipient: secrets,
                                     sender: sender.identity, now: Date())
        guard root.count == 32 else { throw SyncCryptoError.invalidKeyLength }
        try await rootKeys.save(root, accountID: session.accountID)
    }

    private func pendingRecipient(_ id: UUID, session: AccountSession) async throws -> SyncDevicePublicIdentity {
        let devices = try await directory.list(session: session)
        guard let recipient = devices.first(where: { $0.id == id }), recipient.status == .pending else {
            throw SyncError.deviceRejected
        }
        return recipient.identity
    }
}
