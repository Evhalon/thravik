import RedentKit
import Testing
@testable import RedentUI

@MainActor
struct PasswordStorageModelVaultTests {
    @Test func passwordUnlockClaimsDeviceAndSelectsCloudWithoutCopying() async {
        let selector = VaultTestSelector()
        let vault = VaultTestAccess()
        let model = PasswordStorageModel(selector: selector, vault: vault)
        model.accountChanged(signedIn: true)
        var claimedCode: String?
        model.claimDevice = { claimedCode = $0 }
        model.onCloudReady = { model.setAvailable(.redentCloud, available: true) }

        await model.unlock(password: "a sufficiently long password")

        #expect(claimedCode == "recovery-code")
        #expect(model.selectedMode == .redentCloud)
        #expect(await selector.copyingCurrent == false)
        #expect(model.vaultState == .ready)
        #expect(model.passwordConfigured)
    }

    @Test func legacyMigrationAlsoAuthorizesDeviceAndEnablesCloud() async {
        let selector = VaultTestSelector()
        let model = PasswordStorageModel(selector: selector, vault: VaultTestAccess())
        model.accountChanged(signedIn: true)
        var claimedCode: String?
        model.claimDevice = { claimedCode = $0 }
        model.onCloudReady = { model.setAvailable(.redentCloud, available: true) }
        await model.enablePassword(password: "a sufficiently long password", recoveryCode: "legacy-code")
        #expect(claimedCode == "legacy-code")
        #expect(model.selectedMode == .redentCloud)
        #expect(model.vaultState == .ready)
        #expect(await selector.copyingCurrent == false)
    }

    @Test func incorrectPasswordShowsSpecificError() async {
        let model = PasswordStorageModel(selector: VaultTestSelector(), vault: VaultTestAccess())
        model.accountChanged(signedIn: true)
        await model.unlock(password: "wrong password")
        #expect(model.message == "The sync password does not unlock this vault.")
    }
}

private actor VaultTestSelector: PasswordStorageSelecting {
    private(set) var copyingCurrent: Bool?

    func selectedMode() -> PasswordStorageMode { .local }

    func select(_ mode: PasswordStorageMode, copyingCurrent: Bool) {
        self.copyingCurrent = copyingCurrent
    }
}

private actor VaultTestAccess: PasswordVaultAccessing {
    func status() -> PasswordVaultState { .needsRecovery }
    func passwordConfigured() -> Bool { true }
    func prepareVault(password: String) -> String { "recovery-code" }
    func unlock(password: String) throws -> String {
        if password == "wrong password" { throw PasswordStorageError.invalidSyncPassword }
        return "recovery-code"
    }
    func enablePassword(password: String, recoveryCode: String) async {}
    func prepareVault() -> String { "recovery-code" }
    func activateVault() {}
    func recover(code: String) {}
}
