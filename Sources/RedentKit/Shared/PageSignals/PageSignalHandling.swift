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
}

@MainActor
public protocol PageSignalHandling: AnyObject {
    func handle(_ signal: PageSignal, fromTab tabID: UUID)
}

