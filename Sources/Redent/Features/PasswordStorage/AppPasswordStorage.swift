import Foundation
import RedentKit
import RedentSync
import RedentUI
import RedentVault

@MainActor
final class AppPasswordStorage {
    let router: PasswordStorageRouter
    let model: PasswordStorageModel
    var devices: DeviceMembershipModel? { cloud?.syncDevices }
    let account: AppAccount
    let cloud: AppCloudPasswords?
    private var cloudStore: CloudCredentialStore?
    private var accountID: UUID?
    private var cloudTask: Task<Bool, any Error>?
    private var attachment: Task<Void, Never>?
    let turnstile = SyncTurnstile()
    var afterSync: (() async -> Void)?
    var onAccount: ((AccountSession?) -> Void)?
    var onVaultReady: (() -> Void)?
    var prepareBookmarks: (() async throws -> Void)?

    init(local: any CredentialStoring, account: AppAccount) {
        self.account = account
        let bundleID = Bundle.main.bundleIdentifier ?? "app.redent.browser.debug"
        let preferences = UserDefaultsPasswordStoragePreference(suiteName: bundleID)
        router = PasswordStorageRouter(local: local, preferences: preferences)
        cloud = account.configuration.map { AppCloudPasswords(configuration: $0, sessions: account.sessions) }
        model = PasswordStorageModel(selector: router, vault: cloud?.access)
        model.onCloudReady = { [weak self] in try await self?.attachCloud() }
        model.claimDevice = { [weak self] code in try await self?.cloud?.syncDevices.authorize(recoveryCode: code) }
        model.synchronizeCloud = { [weak self] in
            guard let self else { throw PasswordStorageError.unavailable }
            return try await self.synchronize()
        }
        model.loadConflicts = { [weak self] in try await self?.cloudStore?.conflicts() ?? [] }
        model.resolveConflict = { [weak self] id, keepingLocal in
            guard let store = self?.cloudStore else { throw SyncError.unauthorized }
            try await store.resolveConflict(id: id, keepingLocal: keepingLocal)
        }
        configureICloud(bundleID: bundleID)
        account.model.onSessionChanged = { [weak self] session in self?.accountChanged(session) }
    }

    private func configureICloud(bundleID: String) {
        do {
            let configuration = try ICloudCredentialStore.systemConfiguration(
                service: KeychainNamespace.service("app.redent.icloud.credentials"), bundleID: bundleID)
            let store = ICloudCredentialStore(configuration: configuration)
            attachment = Task { [router, model] in
                await router.register(store, for: .iCloud)
                model.setAvailable(.iCloud, available: true)
            }
        } catch {
            model.iCloudUnavailableReason = "iCloud passwords require a signed build with Keychain access enabled."
        }
    }

    private func accountChanged(_ session: AccountSession?) {
        guard accountID != session?.accountID else { return }
        attachment?.cancel()
        let previous = attachment
        accountID = session?.accountID
        cloudTask?.cancel()
        cloudStore = nil
        model.cancelSynchronization()
        model.accountChanged(signedIn: session != nil)
        model.onProviderChanged?()
        onAccount?(session)
        attachment = Task { [weak self, router] in
            await previous?.value
            await router.unregister(.redentCloud)
            guard !Task.isCancelled, let self else { return }
            await self.model.restore()
        }
    }

    private func attachCloud() async throws {
        guard let cloud, let accountID,
              try await account.sessions.load()?.accountID == accountID else { throw SyncError.unauthorized }
        try await cloud.prepareDevice()
        if cloudStore == nil {
            let store = cloud.makeStore(accountID: accountID)
            let notifier = CloudCredentialNotifier(underlying: store, prepareAccess: { [weak self] in
                await self?.prioritizeLocalAccess()
            }, changed: { [weak model] in
                Task { @MainActor in model?.scheduleSynchronization() }
            })
            await router.register(notifier, for: .redentCloud)
            guard self.accountID == accountID else { throw SyncError.accountMismatch }
            cloudStore = store
        }
        model.setAvailable(.redentCloud, available: true)
        try await prepareBookmarks?()
        onVaultReady?()
        model.scheduleSynchronization()
    }

    private func prioritizeLocalAccess() async {
        model.cancelSynchronization()
        let running = cloudTask
        running?.cancel()
        _ = try? await running?.value
    }

    private func synchronize() async throws -> Bool {
        let task = Task { [weak self] in
            guard let self else { throw SyncError.unauthorized }
            return try await self.performSynchronization()
        }
        cloudTask = task
        defer { cloudTask = nil }
        return try await task.value
    }

    private func performSynchronization() async throws -> Bool {
        try await turnstile.run {
            let result = try await self.performCloudSync()
            await self.afterSync?()
            return result
        }
    }

    private func performCloudSync() async throws -> Bool {
        guard let cloudStore, let accountID else { throw SyncError.unauthorized }
        await account.model.restore()
        guard let session = try await account.sessions.load(), session.accountID == accountID,
              session.expiresAt > Date() else { throw SyncError.unauthorized }
        try Task.checkCancellation()
        let result = try await cloudStore.synchronize(session: session)
        if result.uploaded > 0 || result.downloaded > 0 { model.onProviderChanged?() }
        return result.hasMore
    }
}
