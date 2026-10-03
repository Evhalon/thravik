import Foundation
import Observation
import RedentKit

@MainActor @Observable
public final class PasswordStorageModel {
    public private(set) var conflicts: [PasswordConflict] = []
    public private(set) var selectedMode: PasswordStorageMode = .local
    public private(set) var availableModes: Set<PasswordStorageMode> = [.local]
    public private(set) var vaultState: PasswordVaultState?
    public private(set) var recoveryCode: String?
    public private(set) var isBusy = false
    public private(set) var message: String?
    public private(set) var isCloudSignedIn = false
    public var iCloudUnavailableReason: String?
    private let selector: any PasswordStorageSelecting
    private let vault: (any PasswordVaultAccessing)?
    @ObservationIgnored public var loadConflicts: (@MainActor () async throws -> [PasswordConflict])?
    @ObservationIgnored public var resolveConflict: (@MainActor (UUID, Bool) async throws -> Void)?
    @ObservationIgnored public var onCloudReady: (@MainActor () async throws -> Void)?
    @ObservationIgnored public var onProviderChanged: (@MainActor () -> Void)?
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored public var synchronizeCloud: (@MainActor () async throws -> Bool)?
    @ObservationIgnored public var claimDevice: (@MainActor (String) async throws -> Void)?

    public init(selector: any PasswordStorageSelecting, vault: (any PasswordVaultAccessing)? = nil) {
        self.selector = selector
        self.vault = vault
    }

    public func setAvailable(_ mode: PasswordStorageMode, available: Bool) {
        if available { availableModes.insert(mode) } else { availableModes.remove(mode) }
    }

    public func accountChanged(signedIn: Bool) {
        isCloudSignedIn = signedIn
        recoveryCode = nil
        conflicts = []
        vaultState = nil
        setAvailable(.redentCloud, available: false)
    }

    public func restore() async {
        selectedMode = (try? await selector.selectedMode()) ?? .local
        guard !isBusy, isCloudSignedIn, let vault else { return }
        await perform {
            vaultState = try await vault.status()
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

    public func activateVault() async {
        guard !isBusy, recoveryCode != nil, isCloudSignedIn, let vault else { return }
        await perform {
            try await vault.activateVault()
            recoveryCode = nil
            vaultState = .ready
            try await onCloudReady?()
        }
    }

    public func recover(code: String) async {
        guard !isBusy, isCloudSignedIn, let vault else { return }
        await perform {
            try await vault.recover(code: code)
            try await claimDevice?(code)
            vaultState = .ready
            try await onCloudReady?()
        }
    }

    public func synchronize() async {
        guard !isBusy, selectedMode == .redentCloud, availableModes.contains(.redentCloud),
              let synchronizeCloud else { return }
        var hasMore = false
        await perform {
            hasMore = try await synchronizeCloud()
            conflicts = []
            message = hasMore ? "Synchronizing remaining passwords…" : "Passwords synchronized."
        }
        if hasMore { scheduleSynchronization() }
    }

    public func resolve(id: UUID, keepingLocal: Bool) async {
        guard !isBusy, let resolveConflict else { return }
        await perform {
            try await resolveConflict(id, keepingLocal)
            conflicts.removeAll { $0.id == id }
        }
        scheduleSynchronization()
    }

    public func scheduleSynchronization() {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
            await self?.synchronize()
        }
    }

    public func cancelSynchronization() {
        syncTask?.cancel()
        syncTask = nil
    }

    private func perform(_ action: () async throws -> Void) async {
        isBusy = true
        message = nil
        defer { isBusy = false }
        do { try await action() }
        catch is CancellationError { }
        catch SyncError.revisionConflict {
            message = "Password conflict. Your local changes were preserved."
            if let loadConflicts { conflicts = (try? await loadConflicts()) ?? [] }
        }
        catch PasswordStorageError.conflictingCredentials { message = "Different passwords exist for the same login. Copy was stopped." }
        catch SyncError.quotaExceeded { message = "Cloud storage limit reached. Your local changes were preserved." }
        catch SyncError.deviceAuthenticationRequired { message = "This Mac is not authorized to sync passwords yet." }
        catch SyncError.deviceRejected { message = "A cloud change failed device verification. Local passwords were kept." }
        catch SyncError.backendNotConfigured { message = "Cloud sync is not configured on the server. Contact support." }
        catch { message = "Password storage is unavailable. Try again." }
    }
}
