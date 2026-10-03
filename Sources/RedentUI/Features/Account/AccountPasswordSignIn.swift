import RedentDesign
import SwiftUI

struct AccountPasswordSignIn: View {
    @Bindable var model: AccountModel
    @Binding var email: String
    @Binding var password: String
    let forgotPassword: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AccountSignInField(placeholder: "Password", text: $password, isSecure: true,
                               onSubmit: signIn)
            AccountSignInButton(title: "Sign in with Email", prominent: true,
                                isEnabled: canSignIn && !model.isBusy, action: signIn)
            Button("Forgot password?") { forgotPassword() }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Palette.accent)
                .disabled(model.isBusy || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var canSignIn: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    private func signIn() {
        Task { await model.signInWithPassword(email: email, password: password) }
    }
}
