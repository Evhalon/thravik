import Foundation
import RedentKit

struct SyncDeviceRegistration: Sendable {
    let deviceKeys: any SyncDeviceKeyStoring
    let directory: any SyncDeviceDirectorying
    private let crypto = SyncDeviceCryptography()

    func ensure(session: AccountSession) async throws -> SyncDeviceSecrets {
        if let existing = try await deviceKeys.load(accountID: session.accountID) {
            try await reconcile(existing, session: session)
            return existing
        }
        let secrets = crypto.generate()
        try await deviceKeys.save(secrets, accountID: session.accountID)
        try await register(secrets, session: session)
        return secrets
    }

    private func reconcile(_ secrets: SyncDeviceSecrets, session: AccountSession) async throws {
        let identity = try crypto.identity(from: secrets)
        let listed = try await directory.list(session: session)
        guard let current = listed.first(where: { $0.id == identity.id }) else {
            try await register(secrets, session: session)
            return
        }
        guard current.status != .revoked, current.agreementPublicKey == identity.agreementPublicKey,
              current.signingPublicKey == identity.signingPublicKey else { throw SyncError.deviceRejected }
        guard current.status == .pending, current.expiresAt.map({ $0 <= Date() }) ?? true else { return }
        try await enroll(identity, credential: secrets.credential, session: session)
    }

    private func register(_ secrets: SyncDeviceSecrets, session: AccountSession) async throws {
        let identity = try crypto.identity(from: secrets)
        do {
            try await directory.bootstrap(identity, credential: secrets.credential, session: session)
        } catch SyncError.deviceAlreadyRegistered {
            try await enroll(identity, credential: secrets.credential, session: session)
        }
    }

    private func enroll(_ identity: SyncDevicePublicIdentity, credential: Data, session: AccountSession) async throws {
        let expiry = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 + 900).rounded(.down))
        try await directory.enroll(identity, credential: credential, expiresAt: expiry, session: session)
    }
}
