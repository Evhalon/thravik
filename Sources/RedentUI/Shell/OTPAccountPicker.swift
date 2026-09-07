import RedentDesign
import SwiftUI

/// Shown only when more than one Authenticator account plausibly belongs to the
/// current site. Choosing one pins it, so the ambiguity is asked about once.
struct OTPAccountPicker: View {
    @Bindable var model: BrowserModel

    var body: some View {
        Menu {
            ForEach(model.otp.suggestions) { suggestion in
                Button {
                    Task {
                        await model.otp.remember(suggestion)
                        await model.selectedTab?.fillOTPCode(suggestion.code.digits)
                        model.otp.markFilled(at: model.selectedTab?.url)
                    }
                } label: {
                    Text("\(suggestion.account.displayName) — \(suggestion.code.grouped)")
                }
            }
        } label: {
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Use a different account")
    }
}
