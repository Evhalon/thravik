import RedentKit

@MainActor
public struct BrowserFeatures {
    public let autofill: AutofillCoordinator
    public let otp: OTPCoordinator
    public let twoFactor: TwoFactorSetupCoordinator
    public let suggestions: AddressSuggestionsModel

    public init(
        autofill: AutofillCoordinator,
        otp: OTPCoordinator,
        twoFactor: TwoFactorSetupCoordinator,
        suggestions: AddressSuggestionsModel
    ) {
        self.autofill = autofill
        self.otp = otp
        self.twoFactor = twoFactor
        self.suggestions = suggestions
    }
}
