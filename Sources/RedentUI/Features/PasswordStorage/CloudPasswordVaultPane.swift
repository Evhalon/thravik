import SwiftUI

struct CloudPasswordVaultPane: View {
    @Bindable var model: PasswordStorageModel
    @State private var masterPassword = ""
    @State private var confirmation = ""
    @State private var recoveryCode = ""
    @State private var savedRecoveryCode = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let recovery = model.recoveryCode {
                RecoveryCodeCard(code: recovery, saved: $savedRecoveryCode) {
                    Task { await model.activateVault() }
                }
            } else if model.vaultState == .needsCreation {
                creationForm
            } else if model.vaultState == .needsRecovery {
                unlockForm
            } else if model.vaultState == .ready, model.passwordConfigured {
                Text("Cloud passwords and Spaces are unlocked on this Mac.")
                DisclosureGroup("Change or reset sync password") { legacyMigrationForm }
                if model.copyLocalBookmarks != nil {
                    Button("Copy local bookmarks to this account") { Task { await model.copyBookmarksToAccount() } }
                }
            } else if model.vaultState == .ready, model.passwordConfigurationKnown {
                legacyMigrationForm
            } else if model.vaultState == .ready {
                Text("The vault is available on this Mac. Connect to check sync password settings.")
            } else {
                Button("Check Cloud Vault") { Task { await model.restore() } }
            }
        }
        .onChange(of: model.recoveryCode) { _, _ in savedRecoveryCode = false }
    }

    private var creationForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Create a sync password used to unlock your encrypted data on any Mac.")
            SecureField("Sync password (12 characters minimum)", text: $masterPassword)
            SecureField("Confirm sync password", text: $confirmation)
            Button("Create Encrypted Vault") {
                Task { await model.prepareVault(password: masterPassword); clearPasswords() }
            }
            .disabled(!passwordsMatch)
        }
    }

    private var unlockForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            if model.passwordConfigured {
                SecureField("Sync password", text: $masterPassword)
                Button("Unlock Cloud Data") {
                    Task { await model.unlock(password: masterPassword); clearPasswords() }
                }
                .disabled(masterPassword.isEmpty)
            } else {
                SecureField("Recovery code", text: $recoveryCode)
                Button("Recover Cloud Data") {
                    Task { await model.recover(code: recoveryCode); recoveryCode = "" }
                }
                .disabled(recoveryCode.isEmpty)
            }
            recoveryDisclosure
        }
    }

    private var legacyMigrationForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Use your recovery code to set a sync password. Your encrypted data stays unchanged.")
            SecureField("Existing recovery code", text: $recoveryCode)
            SecureField("New sync password (12 characters minimum)", text: $masterPassword)
            SecureField("Confirm sync password", text: $confirmation)
            Button("Set Sync Password") {
                Task {
                    await model.enablePassword(password: masterPassword, recoveryCode: recoveryCode)
                    clearPasswords()
                    recoveryCode = ""
                }
            }
            .disabled(!passwordsMatch || recoveryCode.isEmpty)
        }
    }

    private var recoveryDisclosure: some View {
        DisclosureGroup("Use a recovery code instead") {
            SecureField("Recovery code", text: $recoveryCode)
            Button("Unlock with Recovery Code") {
                Task { await model.recover(code: recoveryCode); recoveryCode = ""; clearPasswords() }
            }
            .disabled(recoveryCode.isEmpty)
        }
        .disabled(!model.passwordConfigured)
    }

    private var passwordsMatch: Bool {
        masterPassword.count >= 12 && masterPassword == confirmation
    }

    private func clearPasswords() {
        masterPassword = ""
        confirmation = ""
    }
}
