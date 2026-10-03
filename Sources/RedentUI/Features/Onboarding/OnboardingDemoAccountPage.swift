import RedentDesign
import SwiftUI

struct OnboardingDemoAccountPage: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let account = model.demoAccount {
                AccountSignInPage(model: account)
                    .onChange(of: account.session?.accountID) { _, accountID in
                        if accountID != nil { model.advance() }
                    }
            }
            Text("Demo only. Sign-in stays in memory. Any non-empty password or 6-digit code works. No email is sent; no account changes.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.chromeSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button("Continue on this Mac for now") { model.advance() }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.chromeSecondaryText)
        }
    }
}
