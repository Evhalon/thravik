import Foundation
import Testing
import RedentKit
@testable import RedentUI

@MainActor
struct AccountModelTests {
    @Test func loginPersistsBeforePublishingAndLogoutClearsSession() async throws {
        let authentication = AccountAuthenticationFake()
        let storage = AccountSessionFake()
        let model = AccountModel(authentication: authentication, sessions: storage)
        await model.requestEmailCode(email: "user@example.com")
        #expect(model.awaitingEmailCode)
        await model.verifyEmailCode(email: "user@example.com", code: "123456")
        #expect(model.session == authentication.session)
        #expect(await storage.load() == authentication.session)
        await model.signOut()
        #expect(model.session == nil)
        #expect(await storage.load() == nil)
    }

    @Test func failedStorageNeverPublishesSignedInState() async {
        let storage = AccountSessionFake(fails: true)
        let model = AccountModel(authentication: AccountAuthenticationFake(), sessions: storage)
        await model.requestEmailCode(email: "user@example.com")
        await model.verifyEmailCode(email: "user@example.com", code: "123456")
        #expect(model.session == nil)
        #expect(model.errorMessage != nil)
        #expect(!model.isBusy)
    }

    @Test func offlineRefreshPreservesCachedIdentity() async throws {
        let storage = AccountSessionFake()
        let cached = AccountSession(accountID: UUID(), accessToken: "expired", refreshToken: "test",
                                    expiresAt: .distantPast)
        try await storage.save(cached)
        var authentication = AccountAuthenticationFake()
        authentication.failsRefresh = true
        let model = AccountModel(authentication: authentication, sessions: storage)
        var published: AccountSession?
        model.onSessionChanged = { published = $0 }
        await model.restore()
        #expect(model.session == cached)
        #expect(published == cached)
        #expect(await storage.load() == cached)
    }

    @Test func freshCachedSessionRestoresWithoutSavingAgain() async {
        let cached = AccountSession(accountID: UUID(), accessToken: "access", refreshToken: "refresh",
                                    expiresAt: .distantFuture)
        let identity = AccountSession(accountID: cached.accountID, accessToken: cached.accessToken,
                                      refreshToken: cached.refreshToken, expiresAt: cached.expiresAt,
                                      identity: AccountIdentity(email: "user@example.com", loginMethod: .email))
        let storage = AccountSessionFake(fails: true, value: identity)
        let model = AccountModel(authentication: AccountAuthenticationFake(), sessions: storage)
        var publications = 0
        model.onSessionChanged = { _ in publications += 1 }
        await model.restore()
        #expect(model.session == identity)
        #expect(model.errorMessage == nil)
        #expect(publications == 1)
    }

    @Test func invalidCodeAndRateLimitKeepEmailChallengeAvailable() async {
        for error in [AccountError.invalidCode, .rateLimited] {
            let authentication = AccountAuthenticationFake(verificationError: error)
            let model = AccountModel(authentication: authentication, sessions: AccountSessionFake())
            await model.requestEmailCode(email: "user@example.com")
            await model.verifyEmailCode(email: "user@example.com", code: "123456")
            #expect(model.awaitingEmailCode)
            #expect(model.errorMessage != nil)
        }
    }

    @Test func googleSignInPersistsSessionBeforePublishing() async throws {
        let google = GoogleAuthenticationFake()
        let storage = AccountSessionFake()
        let model = AccountModel(authentication: AccountAuthenticationFake(), sessions: storage, google: google)
        model.presentGoogle = { _ in try #require(URL(string: "redent://account/callback?code=ok")) }
        await model.signInWithGoogle()
        #expect(model.session == google.session)
        #expect(await storage.load() == google.session)
    }

    @Test func blankEmailDoesNotAskForACode() async {
        let model = AccountModel(authentication: AccountAuthenticationFake(), sessions: AccountSessionFake())
        await model.requestEmailCode(email: "   ")
        #expect(!model.awaitingEmailCode)
        await model.requestEmailCode(email: " user@example.com ")
        #expect(model.awaitingEmailCode)
        model.cancelEmailCode()
        #expect(!model.awaitingEmailCode)
    }

    @Test func unconfiguredModelPerformsNoAuthentication() async {
        let model = AccountModel(authentication: nil, sessions: AccountSessionFake())
        await model.requestEmailCode(email: "user@example.com")
        #expect(!model.isConfigured)
        #expect(!model.awaitingEmailCode)
    }
}

private struct AccountAuthenticationFake: AccountAuthenticating {
    let session = AccountSession(accountID: UUID(), accessToken: "access", refreshToken: "refresh", expiresAt: .distantFuture)
    var verificationError: AccountError?
    func requestEmailCode(email: String) async throws {}
    func verifyEmailCode(email: String, code: String) async throws -> AccountSession {
        if let verificationError { throw verificationError }
        return session
    }
    var failsRefresh = false
    func refresh(session: AccountSession) async throws -> AccountSession {
        if failsRefresh { throw AccountError.unavailable }
        return session
    }
    func signOut(session: AccountSession) async throws {}
}

private struct GoogleAuthenticationFake: GoogleAccountAuthenticating {
    let session = AccountSession(accountID: UUID(), accessToken: "google", refreshToken: "refresh",
                                 expiresAt: .distantFuture)
    func authorizationURL() async throws -> URL { try #require(URL(string: "https://accounts.example.com")) }
    func completeGoogleSignIn(callback: URL) async throws -> AccountSession { session }
    func cancelGoogleSignIn() async {}
}

private actor AccountSessionFake: AccountSessionStoring {
    var value: AccountSession?
    let fails: Bool
    init(fails: Bool = false, value: AccountSession? = nil) {
        self.fails = fails
        self.value = value
    }
    func load() -> AccountSession? { value }
    func save(_ session: AccountSession) throws {
        if fails { throw AccountError.unavailable }
        value = session
    }
    func clear() { value = nil }
}
