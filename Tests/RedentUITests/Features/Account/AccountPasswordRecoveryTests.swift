import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
struct AccountPasswordRecoveryTests {
    @Test func verifiedRecoverySessionStaysPrivateUntilUpdateAndSaveSucceed() async throws {
        let auth = RecoveryAuthenticationFake()
        let storage = RecoverySessionStore(fails: true)
        let model = AccountModel(authentication: auth, sessions: storage)
        var published = 0
        model.onSessionChanged = { _ in published += 1 }
        await model.requestPasswordRecovery(email: "person@example.com")
        await model.verifyPasswordRecoveryCode(email: "person@example.com", code: "123456")
        #expect(model.awaitingNewPassword)
        #expect(model.session == nil)
        #expect(published == 0)
        await model.completePasswordRecovery(password: "new-password", confirmation: "new-password")
        #expect(model.session == nil)
        #expect(published == 0)
        #expect(model.errorMessage != nil)
        #expect(model.awaitingNewPassword)
        #expect(await auth.passwordUpdates == 1)
        await storage.setFails(false)
        await model.completePasswordRecovery(password: "new-password", confirmation: "new-password")
        #expect(model.session == auth.recovered)
        #expect(published == 1)
    }

    @Test func passwordMismatchNeverCallsPasswordUpdate() async {
        let auth = RecoveryAuthenticationFake()
        let model = AccountModel(authentication: auth, sessions: RecoverySessionStore())
        await model.requestPasswordRecovery(email: "person@example.com")
        await model.verifyPasswordRecoveryCode(email: "person@example.com", code: "123456")
        await model.completePasswordRecovery(password: "new-password", confirmation: "different")
        #expect(model.session == nil)
        #expect(model.errorMessage == "Passwords do not match.")
        #expect(await auth.passwordUpdates == 0)
    }

    @Test func recoveryCanBeCancelledWithoutPublishingSession() async {
        let model = AccountModel(authentication: RecoveryAuthenticationFake(), sessions: RecoverySessionStore())
        await model.requestPasswordRecovery(email: "person@example.com")
        await model.verifyPasswordRecoveryCode(email: "person@example.com", code: "123456")
        model.cancelPasswordRecovery()
        await model.completePasswordRecovery(password: "new-password", confirmation: "new-password")
        #expect(!model.awaitingNewPassword)
        #expect(model.session == nil)
    }
}

private actor RecoveryAuthenticationFake: AccountAuthenticating {
    let recovered = AccountSession(accountID: UUID(), accessToken: "recovery-access",
                                   refreshToken: "recovery-refresh", expiresAt: .distantFuture)
    private(set) var passwordUpdates = 0
    func requestEmailCode(email: String) async throws {}
    func verifyEmailCode(email: String, code: String) async throws -> AccountSession { recovered }
    func requestPasswordRecovery(email: String) async throws {}
    func verifyPasswordRecoveryCode(email: String, code: String) async throws -> AccountSession { recovered }
    func updatePassword(session: AccountSession, password: String) async throws { passwordUpdates += 1 }
    func refresh(session: AccountSession) async throws -> AccountSession { session }
    func signOut(session: AccountSession) async throws {}
    func signInWithPassword(email: String, password: String) async throws -> AccountSession { recovered }
}

private actor RecoverySessionStore: AccountSessionStoring {
    private var fails: Bool
    private var session: AccountSession?
    init(fails: Bool = false) { self.fails = fails }
    func load() -> AccountSession? { session }
    func save(_ session: AccountSession) throws {
        if fails { throw AccountError.unavailable }
        self.session = session
    }
    func clear() { session = nil }
    func setFails(_ fails: Bool) { self.fails = fails }
}
