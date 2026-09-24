import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// Regression cover for sign-in pills appearing on pages that ask for no
/// sign-in: a newsletter email box, a card's security code, a postcode.
@Suite("Sign-in detection")
@MainActor
struct SignInDetectionTests {
    @Test("A newsletter email box on an article is not a login form")
    func newsletterIsNotLogin() async throws {
        let signals = try await signals(for: "<form><input type='email' name='email' placeholder='Your email'></form>",
                                        path: "/blog/article")
        #expect(!signals.contains { if case .loginFormDetected = $0 { true } else { false } })
    }

    @Test("A visible password field is a login form")
    func passwordIsLogin() async throws {
        let signals = try await signals(for: "<form><input name='user'><input type='password'></form>", path: "/")
        #expect(signals.contains { if case .loginFormDetected = $0 { true } else { false } })
    }

    @Test("An email-first sign-in screen is still a login form")
    func emailFirstSignIn() async throws {
        let signals = try await signals(for: "<form><input type='email' name='email'></form>", path: "/signin")
        #expect(signals.contains { if case .loginFormDetected = $0 { true } else { false } })
    }

    @Test("A card security code is not a one-time code")
    func cardCodeIsNotOTP() async throws {
        let body = "<label for='c'>Card security code</label><input id='c' name='cvc' type='text'>"
        let signals = try await signals(for: body, path: "/checkout")
        #expect(!signals.contains { if case .otpFieldAppeared = $0 { true } else { false } })
    }

    @Test("An explicit one-time-code field is still found")
    func explicitOTP() async throws {
        let signals = try await signals(for: "<input autocomplete='one-time-code' type='text'>", path: "/verify")
        #expect(signals.contains { if case .otpFieldAppeared = $0 { true } else { false } })
    }

    private func signals(for body: String, path: String) async throws -> [PageSignal] {
        let recorder = SignalRecorder()
        let controller = TabController(
            session: BrowserSession(tabs: [TabSnapshot()], selectedTabID: nil),
            settings: BrowserSettings(),
            logger: DetectionLogger()
        )
        controller.signalHandler = recorder
        let tab = try #require(controller.webTabs.first)
        tab.wake(loading: nil)
        let view = try #require(tab.webView)
        view.frame = CGRect(x: 0, y: 0, width: 800, height: 600)
        view.loadHTMLString("<body>\(body)</body>", baseURL: URL(string: "https://example.com\(path)"))
        // The page script scans once on load; give it room, then a little more
        // so a signal it should not send has had every chance to arrive.
        for _ in 0..<150 where recorder.signals.isEmpty {
            try await Task.sleep(for: .milliseconds(20))
        }
        try await Task.sleep(for: .milliseconds(400))
        withExtendedLifetime(controller) {}
        return recorder.signals
    }
}

@MainActor
private final class SignalRecorder: PageSignalHandling {
    var signals: [PageSignal] = []
    func handle(_ signal: PageSignal, fromTab tabID: UUID) { signals.append(signal) }
}

private struct DetectionLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
