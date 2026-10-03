import Foundation
import RedentKit
import RedentSync
import RedentUI
import RedentVault

@MainActor
final class AppCloudPasswords {
    let access: CloudPasswordVaultAccess
    let syncDevices: DeviceMembershipModel
    private let configuration: SupabaseConfiguration
    private let sessions: any AccountSessionStoring
    private let keys: KeychainSyncKeyStore
    private let deviceKeys: KeychainSyncDeviceStore
    private let directory: SupabaseDeviceDirectory

    init(configuration: SupabaseConfiguration, sessions: any AccountSessionStoring) {
        self.configuration = configuration
        self.sessions = sessions
        keys = KeychainSyncKeyStore(service: KeychainNamespace.service("app.redent.sync.keys"))
        deviceKeys = KeychainSyncDeviceStore(service: KeychainNamespace.service("app.redent.sync.devices"))
        directory = SupabaseDeviceDirectory(configuration: configuration)
        let coordinator = SyncDeviceCoordinator(sessions: sessions, rootKeys: keys,
                                                deviceKeys: deviceKeys, directory: directory)
        syncDevices = DeviceMembershipModel(manager: coordinator)
        let recovery = SupabaseRecoveryEnvelopeStore(configuration: configuration)
        let underlying = CloudVaultAccess(configuration: .init(keys: keys, sessions: sessions,
            envelopes: recovery, claims: RecoveryClaimPublisher(directory: directory)))
        access = CloudPasswordVaultAccess(underlying: underlying, sessions: sessions,
            envelopes: SupabasePasswordEnvelopeStore(configuration: configuration), recovery: recovery)
    }

    func prepareDevice() async throws { try await syncDevices.prepareForSync() }

    func makeStore(accountID: UUID) -> CloudCredentialStore {
        let local = KeychainCredentialStore(
            service: KeychainNamespace.service("app.redent.cloud.credentials.\(accountID.uuidString)"),
            preservesDistinctRecords: true)
        let transport = signedTransport(accountID: accountID)
        let services = CloudCredentialStore.Services(
            replica: replica(accountID: accountID), keys: keys, transport: transport, sessions: sessions)
        return CloudCredentialStore(configuration: .init(accountID: accountID, local: local, services: services))
    }

    func makeWorkspaceStore(accountID: UUID) -> WorkspaceSyncStore {
        WorkspaceSyncStore(accountID: accountID, dependencies: .init(
            replica: replica(accountID: accountID), keys: keys, deviceKeys: deviceKeys,
            transport: signedTransport(accountID: accountID), sessions: sessions))
    }

    func makeBookmarkStore(accountID: UUID, bookmarks: any BookmarkStoring) -> BookmarkSyncStore {
        BookmarkSyncStore(accountID: accountID, dependencies: .init(
            replica: replica(accountID: accountID), keys: keys, deviceKeys: deviceKeys,
            transport: signedTransport(accountID: accountID), sessions: sessions), bookmarks: bookmarks)
    }

    func discardReplica(accountID: UUID) { replicas[accountID] = nil }

    private var replicas: [UUID: AuthenticatedSyncLocalStore] = [:]

    private func replica(accountID: UUID) -> AuthenticatedSyncLocalStore {
        if let existing = replicas[accountID] { return existing }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let bundle = Bundle.main.bundleIdentifier ?? "app.redent.browser.debug"
        let file = base.appendingPathComponent(bundle).appendingPathComponent("sync-\(accountID.uuidString).sqlite")
        let verified = AuthenticatedSyncLocalStore(
            underlying: SQLiteSyncLocalStore(fileURL: file), cipher: SyncMutationCipher(), keys: keys)
        replicas[accountID] = verified
        return verified
    }

    private func signedTransport(accountID: UUID) -> SigningSyncTransport {
        SigningSyncTransport(inner: SupabaseSyncTransport(configuration: configuration), keys: deviceKeys,
                             directory: directory, accountID: accountID)
    }
}

private struct RecoveryClaimPublisher: RecoveryClaimPublishing {
    let directory: SupabaseDeviceDirectory

    func publish(claimKey: Data, session: AccountSession) async throws {
        try await directory.publishClaim(claimKey, session: session)
    }
}
