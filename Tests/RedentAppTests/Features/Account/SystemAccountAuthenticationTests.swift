import Foundation
@testable import Redent
import RedentKit
import Testing

@MainActor
struct SystemAccountAuthenticationTests {
    @Test func unrelatedCallbackDoesNotConsumeTheLiveAttempt() async throws {
        let opener = CallbackOpeningProbe()
        var activations = 0
        let authentication = SystemAccountAuthentication(browserOpener: opener.open, activate: { activations += 1 })
        let task = Task { try await authentication.authenticate(url: try authorize("expected")) }
        await opener.waitForOpen()
        #expect(authentication.accept(try callback("wrong")))
        #expect(activations == 0)
        let expected = try callback("expected")
        #expect(authentication.accept(expected))
        #expect(try await task.value == expected)
        #expect(activations == 1)
    }

    @Test func cancellationEndsOneAttemptAndNextAttemptStillWorks() async throws {
        let opener = CallbackOpeningProbe()
        let authentication = SystemAccountAuthentication(browserOpener: opener.open, activate: {})
        let cancelled = Task { try await authentication.authenticate(url: try authorize("first")) }
        await opener.waitForOpen()
        cancelled.cancel()
        do { _ = try await cancelled.value; Issue.record("Cancelled authentication succeeded") }
        catch is CancellationError { }
        let next = Task { try await authentication.authenticate(url: try authorize("second")) }
        await opener.waitForOpen()
        #expect(authentication.accept(try callback("first")))
        let expected = try callback("second")
        #expect(authentication.accept(expected))
        #expect(try await next.value == expected)
    }

    @Test func malformedAuthorizationNeverOpensBrowser() async throws {
        let opener = CallbackOpeningProbe()
        let authentication = SystemAccountAuthentication(browserOpener: opener.open, activate: {})
        let url = try #require(URL(string: "https://example.com/auth/v1/authorize"))
        await #expect(throws: AccountError.invalidConfiguration) { try await authentication.authenticate(url: url) }
        #expect(opener.openCount == 0)
    }

    private func authorize(_ state: String) throws -> URL {
        var components = URLComponents(string: "https://example.com/auth/v1/authorize")
        components?.queryItems = [URLQueryItem(name: "redirect_to", value: "redent://account/callback?state=\(state)")]
        return try #require(components?.url)
    }

    private func callback(_ state: String) throws -> URL {
        try #require(URL(string: "redent://account/callback?state=\(state)&code=test-code"))
    }
}

@MainActor
private final class CallbackOpeningProbe {
    private var opened: CheckedContinuation<Void, Never>?
    private var unconsumedOpens = 0
    private(set) var openCount = 0

    func open(_ url: URL) async throws {
        openCount += 1
        if let opened { self.opened = nil; opened.resume() }
        else { unconsumedOpens += 1 }
    }

    func waitForOpen() async {
        if unconsumedOpens > 0 { unconsumedOpens -= 1; return }
        await withCheckedContinuation { opened = $0 }
    }
}
