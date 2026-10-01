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
        if routeVideo(message) { return }
        if routeMedia(message.body) || routeQuiet(message.body) { return }
        if let form = FormSignalParser.parse(message.body) {
            // Positions are only meaningful in the main frame's own viewport.
            guard message.frameInfo.isMainFrame, let tab, let signal = form.resolve(in: tab) else { return }
            tab.receive(signal)
            return
        }
        guard let signal = Self.parse(message.body) else { return }
        tab?.receive(signal)
    }

    private func routeVideo(_ message: WKScriptMessage) -> Bool {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return false }
        guard ["videoState", "floatVideoRequested"].contains(type) else { return false }
        guard message.frameInfo.isMainFrame else { return true }
        if type == "floatVideoRequested", tab?.canFloatVideo == true {
            Task { [weak tab] in _ = await tab?.toggleFloatingVideo() }
        } else if type == "videoState" {
            tab?.receiveVideoState(body)
        }
        return true
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
        case "twoFactorSetupAppeared":
            return parseOrigin(dict).map { .twoFactorSetupAppeared(origin: $0) }
        case "twoFactorSetupGone":
            return .twoFactorSetupGone
        case "extensionInstallRequested":
            return .extensionInstallRequested
        default:
            return nil
        }
    }

    /// Tab audio stays inside the engine: it drives the speaker badge and
    /// keeps a playing tab awake, and no feature above needs the raw events.
    private func routeMedia(_ body: Any) -> Bool {
        guard let dict = body as? [String: Any], let type = dict["type"] as? String else { return false }
        switch type {
        case "mediaReset":
            tab?.resetMediaFrames()
        case "mediaAudible":
            guard let frame = dict["frame"] as? String, frame.count <= 64,
                  let audible = dict["audible"] as? Bool else { return true }
            tab?.mediaFrame(frame, isAudible: audible)
        default:
            return false
        }
        return true
    }

    /// Quiet mode's receipt is the tab's own display state, like its audio.
    private func routeQuiet(_ body: Any) -> Bool {
        guard let dict = body as? [String: Any], let type = dict["type"] as? String else { return false }
        switch type {
        case "quietReset":
            tab?.quietReceipt = QuietReceipt()
        case "quietAction":
            if dict["kind"] as? String == "cookieBanner" { tab?.quietReceipt.declinedCookieBanners += 1 }
            if dict["kind"] as? String == "autoplay" { tab?.quietReceipt.stoppedAutoplays += 1 }
        default:
            return false
        }
        return true
    }

    private static func parseOrigin(_ dict: [String: Any]) -> Origin? {
        guard let raw = dict["origin"] as? String, let url = URL(string: raw) else { return nil }
        return Origin(url: url)
    }
}
