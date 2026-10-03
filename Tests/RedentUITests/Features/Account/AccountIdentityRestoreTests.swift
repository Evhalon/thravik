import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
struct AccountIdentityRestoreTests {
    @Test func legacyRestoreBackfillsEmailWithoutGuessingLoginMethod() async throws {
        let cached = AccountSession(accountID: UUID(), accessToken: "access", refreshToken: "refresh",
                                    expiresAt: .distantFuture)
        let updated = AccountSession(accountID: cached.accountID, accessToken: "access", refreshToken: "refresh",
                                     expiresAt: .distantFuture,
                                     identity: AccountIdentity(email: "real@example.com", loginMethod: .unknown))
        let storage = IdentityStore(cached)
        let model = AccountModel(authentication: IdentityAuthenticator(updated: updated), sessions: storage)
        await model.restore()
        #expect(model.session?.email == "real@example.com")
        #expect(model.session?.loginMethod == .unknown)
        #expect(await storage.load() == updated)
    }
}

private struct IdentityAuthenticator: AccountAuthenticating {
    let updated: AccountSession
    func requestEmailCode(email: String) async throws { }
    func verifyEmailCode(email: String, code: String) async throws -> AccountSession { updated }
    func refresh(session: AccountSession) async throws -> AccountSession { updated }
    func signOut(session: AccountSession) async throws { }
}

private actor IdentityStore: AccountSessionStoring {
    private var value: AccountSession?
    init(_ value: AccountSession) { self.value = value }
    func load() -> AccountSession? { value }
    func save(_ session: AccountSession) { value = session }
    func clear() { value = nil }
}
