import RedentDesign
import SwiftUI

struct OnboardingAccountPage: View {
    @Bindable var onboarding: OnboardingModel
    @Bindable var account: AccountModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            AccountSignInPage(model: account)
                .disabled(account.isBusy)
            if account.isBusy { ProgressView("Connecting…").controlSize(.small) }
            if let error = account.errorMessage {
                Text(error).font(.callout).foregroundStyle(Palette.danger)
            }
            Button("Continue on this Mac for now") { onboarding.advance() }
                .buttonStyle(.plain).foregroundStyle(Palette.chromeSecondaryText)
            Text("You can connect your account later in Settings.")
                .font(.caption).foregroundStyle(Palette.chromeSecondaryText)
        }
        .onChange(of: account.session?.accountID, initial: true) {
            if account.session != nil { onboarding.advance() }
        }
    }
}
