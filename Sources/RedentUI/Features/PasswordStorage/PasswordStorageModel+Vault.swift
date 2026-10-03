import Foundation
import RedentKit

extension PasswordStorageModel {
    public func copyBookmarksToAccount() async {
        guard !isBusy, isCloudSignedIn, let copyLocalBookmarks else { return }
        await perform { try await copyLocalBookmarks() }
    }

    public func prepareVault(password: String) async {
        guard !isBusy, isCloudSignedIn, let vault else { return }
        let generation = accountGeneration
        await perform {
            let code = try await vault.prepareVault(password: password)
            guard isCurrent(generation) else { return }
            recoveryCode = code
            passwordConfigured = true
            passwordConfigurationKnown = true
        }
    }

    public func unlock(password: String) async {
        guard !isBusy, isCloudSignedIn, let vault else { return }
        let generation = accountGeneration
        await perform {
            let code = try await vault.unlock(password: password)
            guard isCurrent(generation) else { return }
            try await claimDevice?(code)
            guard isCurrent(generation) else { return }
            vaultState = .ready
            passwordConfigured = true
            passwordConfigurationKnown = true
            try await activateCloudSync(generation: generation)
        }
        if selectedMode == .redentCloud { scheduleSynchronization() }
    }

    public func enablePassword(password: String, recoveryCode: String) async {
        guard !isBusy, isCloudSignedIn, let vault else { return }
        let generation = accountGeneration
        await perform {
            try await vault.enablePassword(password: password, recoveryCode: recoveryCode)
            guard isCurrent(generation) else { return }
            try await vault.recover(code: recoveryCode)
            guard isCurrent(generation) else { return }
            try await claimDevice?(recoveryCode)
            guard isCurrent(generation) else { return }
            vaultState = .ready
            passwordConfigured = true
            passwordConfigurationKnown = true
            try await activateCloudSync(generation: generation)
        }
    }

    public func activateVault() async {
        guard !isBusy, recoveryCode != nil, isCloudSignedIn, let vault else { return }
        let generation = accountGeneration
        await perform {
            try await vault.activateVault()
            guard isCurrent(generation) else { return }
            recoveryCode = nil
            vaultState = .ready
            passwordConfigured = true
            passwordConfigurationKnown = true
            try await activateCloudSync(generation: generation)
        }
    }

    public func recover(code: String) async {
        guard !isBusy, isCloudSignedIn, let vault else { return }
        let generation = accountGeneration
        await perform {
            try await vault.recover(code: code)
            guard isCurrent(generation) else { return }
            try await claimDevice?(code)
            guard isCurrent(generation) else { return }
            vaultState = .ready
            passwordConfigurationKnown = true
            try await activateCloudSync(generation: generation)
        }
    }
}
