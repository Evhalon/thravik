import RedentKit

@MainActor
public struct BrowserFeatures {
    public let autofill: AutofillCoordinator
    public let otp: OTPCoordinator
    public let suggestions: AddressSuggestionsModel

    public init(autofill: AutofillCoordinator, otp: OTPCoordinator, suggestions: AddressSuggestionsModel) {
        self.autofill = autofill
        self.otp = otp
        self.suggestions = suggestions
    }
}
