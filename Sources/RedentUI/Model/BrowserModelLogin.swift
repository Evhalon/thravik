import Foundation
import RedentKit

/// Signing in, one step at a time: the saved login on a password page, the
/// live code on a one-time-code page, and the site's own two-factor setup
/// saved straight into the vault. Nothing here ever submits a form.
extension BrowserModel {
    public var canFillLogin: Bool { autofill.shouldOfferFill || otp.primary != nil }

    /// ⌘\ — fills whatever this step of the sign-in asks for.
    public func fillLogin() {
        if autofill.shouldOfferFill, let credential = autofill.suggestions.first {
            fillCredential(credential)
        } else if let suggestion = otp.primary {
            Task { await fillOTP(suggestion) }
        }
    }

    public func fillCredential(_ credential: Credential) {
        guard let tab = selectedTab else { return }
        Task {
            await tab.fillCredential(username: credential.username, password: credential.password)
            await autofill.credentialFilled(credential)
        }
    }

    /// Resolves once the code is in the field, so the button can show it landed.
    public func fillOTP(_ suggestion: OTPCoordinator.Suggestion) async {
        guard let tab = selectedTab else { return }
        await tab.fillOTPCode(suggestion.code.digits)
        otp.markFilled(at: tab.url)
        if otp.originMatched { await otp.remember(suggestion) }
    }

    /// Reads the setup QR code off the page and saves it. The setup's own
    /// confirmation field, when it is already showing, gets the new code
    /// offered straight away.
    public func saveTwoFactorSetup() {
        guard let tab = selectedTab else { return }
        Task {
            let image = await tab.visiblePageImage()
            guard let origin = await twoFactor.capture(pageImage: image), otp.origin != nil else { return }
            await otp.fieldAppeared(at: origin, username: autofill.identityHint)
        }
    }
}
