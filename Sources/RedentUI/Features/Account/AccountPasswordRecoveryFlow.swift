import RedentDesign
import SwiftUI

struct AccountPasswordRecoveryFlow: View {
    @Bindable var model: AccountModel
    let email: String
    @State private var code = ""
    @State private var password = ""
    @State private var confirmation = ""
    let cancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(instruction)
                .font(.system(size: 12))
                .foregroundStyle(Palette.chromeSecondaryText)
            if model.awaitingRecoveryCode { recoveryCodeEntry }
            if !model.awaitingRecoveryCode && !model.awaitingNewPassword { requestCodeButton }
            if model.awaitingNewPassword { passwordEntry }
            Button("Cancel password reset", action: cancel)
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Palette.chromeSecondaryText)
                .disabled(model.isBusy)
        }
    }

    private var instruction: String {
        model.awaitingNewPassword ? "Choose a new password for \(email)." : "Reset your password for \(email)."
    }

    private var requestCodeButton: some View {
        AccountSignInButton(title: "Send Reset Code", prominent: true,
                            isEnabled: !model.isBusy && hasEmail, action: requestCode)
    }

    private var recoveryCodeEntry: some View {
        VStack(alignment: .leading, spacing: 10) {
            AccountSignInField(placeholder: "Reset code", text: $code, isCode: true,
                               onSubmit: verifyCode)
            AccountSignInButton(title: "Verify Reset Code", prominent: true,
                                isEnabled: !code.isEmpty && !model.isBusy, action: verifyCode)
            Button("Resend reset code") {
                requestCode()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(Palette.accent)
            .disabled(model.isBusy)
        }
    }

    private var passwordEntry: some View {
        VStack(alignment: .leading, spacing: 10) {
            AccountSignInField(placeholder: "New password (8+ characters)", text: $password,
                               isSecure: true, onSubmit: complete)
            AccountSignInField(placeholder: "Confirm new password", text: $confirmation,
                               isSecure: true, onSubmit: complete)
            if !password.isEmpty && password.count < 8 {
                passwordHint("Use at least 8 characters.")
            } else if !confirmation.isEmpty && password != confirmation {
                passwordHint("Passwords do not match.")
            }
            AccountSignInButton(title: "Update Password", prominent: true,
                                isEnabled: passwordsReady && !model.isBusy, action: complete)
        }
    }

    private var passwordsReady: Bool {
        password.count >= 8 && password == confirmation
    }

    private var hasEmail: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func passwordHint(_ message: String) -> some View {
        Text(message).font(.system(size: 11)).foregroundStyle(Palette.chromeSecondaryText)
    }

    private func verifyCode() {
        Task { await model.verifyPasswordRecoveryCode(email: email, code: code) }
    }

    private func requestCode() {
        Task { await model.requestPasswordRecovery(email: email) }
    }

    private func complete() {
        Task { await model.completePasswordRecovery(password: password, confirmation: confirmation) }
    }
}
