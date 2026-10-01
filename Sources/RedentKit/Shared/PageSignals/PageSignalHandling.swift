import Foundation

/// Emitted by injected page scripts. Carries no page content beyond what the
/// feature needs.
public enum PageSignal: Sendable, Equatable {
    case loginFormDetected(origin: Origin)
    case loginFormGone
    case credentialSubmitted(CredentialCandidate)
    case otpFieldAppeared(origin: Origin, username: String)
    case otpFieldDisappeared
    case identityCaptured(username: String)
    /// The page is showing an authenticator QR code to enroll two-factor.
    case twoFactorSetupAppeared(origin: Origin)
    case twoFactorSetupGone
    /// The user pressed Thravik's install button on a Chrome Web Store page.
    /// Carries nothing: which extension is read from the tab's own URL.
    case extensionInstallRequested
    /// The user clicked or typed in a field form history can fill.
    case formFieldActive(FormFieldFocus)
    /// Focus left the field, the page scrolled, or the user pressed Escape.
    case formFieldInactive
    /// The arrow keys moved the lit suggestion; -1 is none.
    case formSuggestionHighlighted(index: Int)
    /// Return on a lit suggestion.
    case formSuggestionChosen(index: Int)
    /// Values from a form the user sent, still unfiltered.
    case formSubmitted([FormFieldValue])
}

/// One field of a submitted form, as the page reported it.
public struct FormFieldValue: Sendable, Equatable {
    public let field: FormFieldDescriptor
    public let value: String

    public init(field: FormFieldDescriptor, value: String) {
        self.field = field
        self.value = value
    }
}

@MainActor
public protocol PageSignalHandling: AnyObject {
    func handle(_ signal: PageSignal, fromTab tabID: UUID)
}

