import Foundation
import RedentKit

public actor SyncDeviceCoordinator: SyncDeviceManaging {
    private let sessions: any AccountSessionStoring
    private let registration: SyncDeviceRegistration
    private let approvals: SyncDeviceApprovalService
    private let directory: any SyncDeviceDirectorying
    private let crypto = SyncDeviceCryptography()
    private var busy = false

    public init(sessions: any AccountSessionStoring, rootKeys: any SyncKeyStoring,
                deviceKeys: any SyncDeviceKeyStoring, directory: any SyncDeviceDirectorying) {
        self.sessions = sessions
        self.directory = directory
        registration = SyncDeviceRegistration(deviceKeys: deviceKeys, directory: directory)
        approvals = SyncDeviceApprovalService(rootKeys: rootKeys, directory: directory)
    }

    public func prepare() async throws -> [SyncDeviceSummary] {
        try await exclusive {
            let session = try await session()
            let secrets = try await registration.ensure(session: session)
            return try await summaries(session, localID: secrets.deviceID)
        }
    }

    public func publishClaim(recoveryCode: String) async throws {
        try await exclusive {
            let session = try await session()
            let claimKey = try SyncRecoveryCryptography().claimKey(code: recoveryCode, accountID: session.accountID)
            try await directory.publishClaim(claimKey, session: session)
        }
    }

    public func approve(recipientID: UUID) async throws -> [SyncDeviceSummary] {
        try await exclusive {
            let session = try await session()
            let secrets = try await registration.ensure(session: session)
            try await approvals.approve(recipientID: recipientID, secrets: secrets, session: session)
            return try await summaries(session, localID: secrets.deviceID)
        }
    }

    public func importRootKey() async throws -> [SyncDeviceSummary] {
        try await exclusive {
            let session = try await session()
            let secrets = try await registration.ensure(session: session)
            try await approvals.importRoot(secrets: secrets, session: session)
            return try await summaries(session, localID: secrets.deviceID)
        }
    }

    public func revoke(deviceID: UUID) async throws -> [SyncDeviceSummary] {
        try await exclusive {
            let session = try await session()
            let secrets = try await registration.ensure(session: session)
            guard secrets.deviceID != deviceID else { throw SyncError.deviceRejected }
            try await directory.revoke(deviceID: deviceID, approverID: secrets.deviceID,
                                       credential: secrets.credential, session: session)
            return try await summaries(session, localID: secrets.deviceID)
        }
    }

    public func claim(recoveryCode: String) async throws -> [SyncDeviceSummary] {
        try await exclusive {
            let session = try await session()
            let secrets = try await registration.ensure(session: session)
            let claimKey = try SyncRecoveryCryptography().claimKey(code: recoveryCode, accountID: session.accountID)
            try await directory.claim(deviceID: secrets.deviceID, credential: secrets.credential,
                                      claimKey: claimKey, session: session)
            return try await summaries(session, localID: secrets.deviceID)
        }
    }

    private func exclusive<T>(_ body: () async throws -> T) async throws -> T {
        guard !busy else { throw SyncError.alreadyRunning }
        busy = true
        defer { busy = false }
        return try await body()
    }

    private func session() async throws -> AccountSession {
        guard let session = try await sessions.load(), session.expiresAt > Date() else { throw SyncError.unauthorized }
        return session
    }

    private func summaries(_ session: AccountSession, localID: UUID) async throws -> [SyncDeviceSummary] {
        try await directory.list(session: session).map { record in
            SyncDeviceSummary(id: record.id, status: record.status,
                              fingerprint: try crypto.fingerprint(agreement: record.agreementPublicKey,
                                                                  signing: record.signingPublicKey),
                              isLocal: record.id == localID)
        }
    }
}
