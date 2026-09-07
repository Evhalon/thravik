import Foundation
import RedentKit

/// What the page itself tells the browser: login forms appearing, credentials
/// submitted, one-time-code fields. Kept apart from the window's own state so
/// the untrusted-input path is easy to read in one place.
extension BrowserModel: PageSignalHandling {
    public func handle(_ signal: PageSignal, fromTab tabID: UUID) {
        // The active pane only. A form in the pane the user is not typing in
        // must never be offered a saved secret.
        guard tabID == selectedTab?.id else { return }
        switch signal {
        case .loginFormDetected(let formOrigin):
            guard let origin = selectedTab?.origin, origin.matches(formOrigin) else { return }
            Task { await autofill.loginFormAppeared(at: origin) }
        case .loginFormGone:
            autofill.loginFormDisappeared()
        case .credentialSubmitted(let candidate):
            // Temporary browsing does not offer to remember a login: the tab is
            // about to take its storage with it.
            guard selectedTab?.snapshot.isTemporary == false else { return }
            Task { await autofill.credentialSubmitted(candidate) }
        case .otpFieldAppeared(let origin, let username):
            guard settings.showsTOTPButton else { return }
            let hint = username.isEmpty ? autofill.identityHint : username
            Task { await otp.fieldAppeared(at: origin, username: hint) }
        case .otpFieldDisappeared:
            otp.fieldDisappeared()
        case .identityCaptured(let username):
            autofill.captureIdentity(username)
        }
    }
}
