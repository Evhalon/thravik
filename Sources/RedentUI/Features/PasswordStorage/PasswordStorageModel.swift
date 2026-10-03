import Foundation
import Observation
import RedentKit

@MainActor @Observable
public final class PasswordStorageModel {
    public internal(set) var conflicts: [PasswordConflict] = []
    public internal(set) var selectedMode: PasswordStorageMode = .local
    public internal(set) var availableModes: Set<PasswordStorageMode> = [.local]
    public internal(set) var vaultState: PasswordVaultState?
    public internal(set) var passwordConfigured = false
    public internal(set) var passwordConfigurationKnown = false
    public internal(set) var recoveryCode: String?
    public private(set) var isBusy = false
    public internal(set) var message: String?
    public private(set) var isCloudSignedIn = false
    public var iCloudUnavailableReason: String?
    var accountGeneration = UUID()
    private let selector: any PasswordStorageSelecting
    let vault: (any PasswordVaultAccessing)?
    @ObservationIgnored public var loadConflicts: (@MainActor () async throws -> [PasswordConflict])?
    @ObservationIgnored public var resolveConflict: (@MainActor (UUID, Bool) async throws -> Void)?
    @ObservationIgnored public var onCloudReady: (@MainActor () async throws -> Void)?
    @ObservationIgnored public var onProviderChanged: (@MainActor () -> Void)?
    @ObservationIgnored var syncTask: Task<Void, Never>?
    @ObservationIgnored public var synchronizeCloud: (@MainActor () async throws -> Bool)?
    @ObservationIgnored public var claimDevice: (@MainActor (String) async throws -> Void)?
    @ObservationIgnored public var copyLocalBookmarks: (@MainActor () async throws -> Void)?

    public init(selector: any PasswordStorageSelecting, vault: (any PasswordVaultAccessing)? = nil) {
        self.selector = selector
        self.vault = vault
    }

    public func setAvailable(_ mode: PasswordStorageMode, available: Bool) {
        if available { availableModes.insert(mode) } else { availableModes.remove(mode) }
    }

    public func accountChanged(signedIn: Bool) {
        accountGeneration = UUID()
        isCloudSignedIn = signedIn
        recoveryCode = nil
        conflicts = []
        vaultState = nil
        passwordConfigured = false
        passwordConfigurationKnown = false
        setAvailable(.redentCloud, available: false)
    }

    public func restore() async {
        let generation = accountGeneration
        let mode = (try? await selector.selectedMode()) ?? .local
        guard isCurrent(generation) else { return }
        selectedMode = mode
        guard !isBusy, isCloudSignedIn, let vault else { return }
        await perform {
            let state = try await vault.status()
            guard isCurrent(generation) else { return }
            let configuredResult = state == .ready ? try? await vault.passwordConfigured() : try await vault.passwordConfigured()
            guard isCurrent(generation) else { return }
            vaultState = state
            passwordConfigured = configuredResult ?? passwordConfigured
            if configuredResult != nil { passwordConfigurationKnown = true }
            if vaultState == .ready { try await onCloudReady?() }
        }
    }

    public func select(_ mode: PasswordStorageMode, copyingCurrent: Bool) async {
        guard !isBusy, availableModes.contains(mode) else { return }
        await perform {
            try await selector.select(mode, copyingCurrent: copyingCurrent)
            selectedMode = mode
            onProviderChanged?()
        }
        if selectedMode == .redentCloud { scheduleSynchronization() }
    }

    public func prepareVault() async {
        guard !isBusy, isCloudSignedIn, let vault else { return }
        await perform { recoveryCode = try await vault.prepareVault() }
    }

    func perform(_ action: () async throws -> Void) async {
        let generation = accountGeneration
        isBusy = true
        message = nil
        defer { isBusy = false }
        do { try await action() }
        catch is CancellationError { }
        catch SyncError.revisionConflict where isCurrent(generation) {
            message = "Password conflict. Your local changes were preserved."
            if let loadConflicts { conflicts = (try? await loadConflicts()) ?? [] }
        }
        catch PasswordStorageError.conflictingCredentials where isCurrent(generation) { message = "Different passwords exist for the same login. Copy was stopped." }
        catch PasswordStorageError.invalidSyncPassword where isCurrent(generation) { message = "The sync password does not unlock this vault." }
        catch PasswordStorageError.weakSyncPassword where isCurrent(generation) { message = "Choose a sync password with at least 12 characters." }
        catch PasswordStorageError.invalidRecoveryCode where isCurrent(generation) { message = "The recovery code is incorrect." }
        catch SyncError.quotaExceeded where isCurrent(generation) { message = "Cloud storage limit reached. Your local changes were preserved." }
        catch SyncError.deviceAuthenticationRequired where isCurrent(generation) { message = "This Mac is not authorized to sync passwords yet." }
        catch SyncError.deviceRejected where isCurrent(generation) { message = "A cloud change failed device verification. Local passwords were kept." }
        catch SyncError.backendNotConfigured where isCurrent(generation) { message = "Cloud sync is not configured on the server. Contact support." }
        catch { if isCurrent(generation) { message = "Password storage is unavailable. Try again." } }
    }

    func isCurrent(_ generation: UUID) -> Bool { accountGeneration == generation }

    func activateCloudSync(generation: UUID) async throws {
        try await onCloudReady?()
        guard isCurrent(generation), availableModes.contains(.redentCloud) else {
            throw PasswordStorageError.unavailable
        }
        try await selector.select(.redentCloud, copyingCurrent: false)
        guard isCurrent(generation) else { return }
        selectedMode = .redentCloud
        onProviderChanged?()
    }
}
