import RedentDesign
import SwiftUI

/// Google or email, in the same quiet chrome as the new-tab field.
struct AccountSignInPage: View {
    @Bindable var model: AccountModel
    @State private var email = ""
    @State private var code = ""
    @State private var password = ""
    @State private var usesPassword = true
    @State private var resettingPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            heading
            if model.isConfigured {
                controls
            } else {
                Text("Account service is not configured for this build.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
        }
        .frame(maxWidth: 440, alignment: .leading)
        .onChange(of: model.session) { _, session in
            guard session != nil else { return }
            code = ""
            password = ""
            resettingPassword = false
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sign in")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .tracking(-0.3)
                .foregroundStyle(Palette.chromeText)
            Text("Spaces, pins, and cloud passwords follow this account.")
                .font(.system(size: 12.5))
                .foregroundStyle(Palette.chromeSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            AccountSignInButton(title: "Continue with Google", mark: "G", isEnabled: !model.isBusy) {
                Task { await model.signInWithGoogle() }
            }
            AccountSignInDivider()
            if resettingPassword {
                AccountPasswordRecoveryFlow(model: model, email: email, cancel: cancelRecovery)
            } else {
                AccountSignInField(placeholder: "Email", text: $email,
                                   onSubmit: usesPassword ? signIn : sendCode)
                    .disabled(model.awaitingEmailCode || model.awaitingRecoveryCode || model.isBusy)
                modePicker
                if model.awaitingEmailCode {
                    codeEntry
                } else if usesPassword {
                    AccountPasswordSignIn(model: model, email: $email, password: $password,
                                          forgotPassword: beginRecovery)
                } else {
                    AccountSignInButton(title: "Send Email Code", prominent: true,
                                        isEnabled: canSend && !model.isBusy, action: sendCode)
                }
            }
            if let error = model.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            if model.isBusy {
                ProgressView().controlSize(.small).tint(Palette.accent)
            }
        }
    }

    private var modePicker: some View {
        HStack {
            modeButton("Password", selected: usesPassword) { usesPassword = true }
            modeButton("Email code", selected: !usesPassword) { usesPassword = false }
        }
    }

    private func modeButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(selected ? Palette.accent : Palette.chromeSecondaryText)
            .disabled(model.isBusy || model.awaitingEmailCode || model.awaitingRecoveryCode)
    }

    private var codeEntry: some View {
        VStack(alignment: .leading, spacing: 12) {
            AccountSignInField(placeholder: "Email code", text: $code, isCode: true, onSubmit: verify)
                .disabled(model.isBusy)
            AccountSignInButton(title: "Verify Code", prominent: true,
                                isEnabled: canVerify && !model.isBusy, action: verify)
            HStack(spacing: 16) {
                Button("Resend code", action: sendCode)
                Button("Use a different email") {
                    code = ""
                    model.cancelEmailCode()
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(Palette.chromeSecondaryText)
            .disabled(model.isBusy)
        }
    }

    private var canSend: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canVerify: Bool {
        !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendCode() {
        Task { await model.requestEmailCode(email: email) }
    }

    private func verify() {
        Task { await model.verifyEmailCode(email: email, code: code) }
    }

    private func signIn() {
        Task { await model.signInWithPassword(email: email, password: password) }
    }

    private func beginRecovery() {
        resettingPassword = true
        Task { await model.requestPasswordRecovery(email: email) }
    }

    private func cancelRecovery() {
        resettingPassword = false
        model.cancelPasswordRecovery()
    }
}
