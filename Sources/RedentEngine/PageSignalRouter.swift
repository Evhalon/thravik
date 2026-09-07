import WebKit
import RedentKit

/// Parses `postMessage` calls from the isolated `redent` content world into
/// typed `PageSignal`s and forwards them to the owning tab.
///
/// Holds `tab` weakly: `WKUserContentController` retains this handler
/// strongly for as long as it is registered, so a strong reference back to
/// `tab` here would keep the tab — and its whole web content process — alive
/// even after `hibernate()`.
@MainActor
final class PageSignalRouter: NSObject, WKScriptMessageHandler {
    private weak var tab: WebTab?

    init(tab: WebTab) {
        self.tab = tab
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let signal = Self.parse(message.body) else { return }
        tab?.receive(signal)
    }

    /// Every field from the page is untrusted input — parse defensively and
    /// discard anything malformed rather than guessing.
    private static func parse(_ body: Any) -> PageSignal? {
        guard let dict = body as? [String: Any], let type = dict["type"] as? String else { return nil }
        switch type {
        case "loginFormDetected":
            guard let origin = parseOrigin(dict) else { return nil }
            return .loginFormDetected(origin: origin)
        case "loginFormGone":
            return .loginFormGone
        case "credentialSubmitted":
            guard let origin = parseOrigin(dict),
                  let username = dict["username"] as? String,
                  let password = dict["password"] as? String, !password.isEmpty
            else { return nil }
            return .credentialSubmitted(CredentialCandidate(
                origin: origin,
                username: username,
                password: password,
                isPasswordChange: dict["passwordChange"] as? Bool ?? false
            ))
        case "otpFieldAppeared":
            guard let origin = parseOrigin(dict) else { return nil }
            let username = dict["username"] as? String ?? ""
            return .otpFieldAppeared(origin: origin, username: username)
        case "otpFieldDisappeared":
            return .otpFieldDisappeared
        case "identityCaptured":
            guard let username = dict["username"] as? String else { return nil }
            return .identityCaptured(username: username)
        default:
            return nil
        }
    }

    private static func parseOrigin(_ dict: [String: Any]) -> Origin? {
        guard let raw = dict["origin"] as? String, let url = URL(string: raw) else { return nil }
        return Origin(url: url)
    }
}
