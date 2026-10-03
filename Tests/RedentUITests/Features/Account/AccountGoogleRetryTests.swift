import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
struct AccountGoogleRetryTests {
    @Test func transientAndCancelledBrowserAttemptsCanBeRetried() async throws {
        let google = RetryGoogleAuthentication()
        let model = AccountModel(authentication: google, sessions: RetrySessionStore(), google: google)
        var presentationAttempt = 0
        model.presentGoogle = { _ in
            presentationAttempt += 1
            if presentationAttempt == 1 { throw AccountError.unavailable }
            if presentationAttempt == 2 { throw CancellationError() }
            return try #require(URL(string: "redent://account/callback?state=ok"))
        }
        await model.signInWithGoogle()
        #expect(model.session == nil)
        #expect(model.errorMessage != nil)
        await model.signInWithGoogle()
        #expect(model.session == nil)
        #expect(model.errorMessage == nil)
        await model.signInWithGoogle()
        #expect(model.session == google.session)
        #expect(await google.cancellations == 2)
    }
}

private actor RetryGoogleAuthentication: AccountAuthenticating, GoogleAccountAuthenticating {
    let session = AccountSession(accountID: UUID(), accessToken: "google-access", refreshToken: "google-refresh",
                                 expiresAt: .distantFuture)
    private(set) var cancellations = 0
    func authorizationURL() async throws -> URL { try #require(URL(string: "https://accounts.example.com")) }
    func completeGoogleSignIn(callback: URL) async throws -> AccountSession { session }
    func cancelGoogleSignIn() async { cancellations += 1 }
    func requestEmailCode(email: String) async throws {}
    func verifyEmailCode(email: String, code: String) async throws -> AccountSession { session }
    func signInWithPassword(email: String, password: String) async throws -> AccountSession { session }
    func requestPasswordRecovery(email: String) async throws {}
    func verifyPasswordRecoveryCode(email: String, code: String) async throws -> AccountSession { session }
    func updatePassword(session: AccountSession, password: String) async throws {}
    func refresh(session: AccountSession) async throws -> AccountSession { session }
    func signOut(session: AccountSession) async throws {}
}

private actor RetrySessionStore: AccountSessionStoring {
    private var value: AccountSession?
    func load() -> AccountSession? { value }
    func save(_ session: AccountSession) { value = session }
    func clear() { value = nil }
}
