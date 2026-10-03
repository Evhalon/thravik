import SwiftUI

struct CloudPasswordVaultPane: View {
    @Bindable var model: PasswordStorageModel
    @State private var code = ""
    @State private var savedRecoveryCode = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let recovery = model.recoveryCode {
                Text("Save this recovery code in a safe place. It unlocks your encrypted vault and Spaces on another Mac.")
                Text(recovery).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                Toggle("I saved my recovery code", isOn: $savedRecoveryCode)
                Button("Activate Encrypted Vault") { Task { await model.activateVault() } }
                    .disabled(!savedRecoveryCode)
            } else if model.vaultState == .needsCreation {
                Button("Create Encrypted Vault") { Task { await model.prepareVault() } }
            } else if model.vaultState == .needsRecovery {
                SecureField("Recovery code", text: $code)
                Button("Unlock Cloud Passwords") {
                    Task { await model.recover(code: code); code = "" }
                }
            } else if model.vaultState == .ready {
                Text("Cloud password vault unlocked on this Mac.")
            } else {
                Button("Check Cloud Vault") { Task { await model.restore() } }
            }
        }
        .onChange(of: model.recoveryCode) { _, _ in savedRecoveryCode = false }
    }
}
