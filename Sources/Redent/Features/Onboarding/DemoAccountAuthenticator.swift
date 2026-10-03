import Foundation
import RedentKit

actor DemoAccountAuthenticator: AccountAuthenticating, GoogleAccountAuthenticating {
    private let accountID = UUID()
    private var emailChallenge: String?
    private var recoveryChallenge: String?

    func requestEmailCode(email: String) async throws {
        try validate(email: email)
        emailChallenge = email
    }

    func verifyEmailCode(email: String, code: String) async throws -> AccountSession {
        try validate(email: email)
        try validate(code: code)
        guard emailChallenge == email else { throw AccountError.invalidCode }
        emailChallenge = nil
        return makeSession()
    }

    func signInWithPassword(email: String, password: String) async throws -> AccountSession {
        try validate(email: email)
        guard !password.isEmpty else { throw AccountError.invalidPassword }
        return makeSession()
    }

    func requestPasswordRecovery(email: String) async throws {
        try validate(email: email)
        recoveryChallenge = email
    }

    func verifyPasswordRecoveryCode(email: String, code: String) async throws -> AccountSession {
        try validate(email: email)
        try validate(code: code)
        guard recoveryChallenge == email else { throw AccountError.invalidCode }
        recoveryChallenge = nil
        return makeSession()
    }

    func updatePassword(session: AccountSession, password: String) async throws {
        guard session.accountID == accountID else { throw AccountError.unauthorized }
        guard (8...128).contains(password.count) else { throw AccountError.invalidPassword }
    }

    func refresh(session: AccountSession) async throws -> AccountSession {
        guard session.accountID == accountID else { throw AccountError.unauthorized }
        return makeSession()
    }

    func signOut(session: AccountSession) async throws {}

    func authorizationURL() async throws -> URL {
        guard let url = URL(string: "https://demo.redent.invalid/sign-in") else {
            throw AccountError.invalidConfiguration
        }
        return url
    }

    func completeGoogleSignIn(callback: URL) async throws -> AccountSession { makeSession() }
    func cancelGoogleSignIn() async {}

    private func makeSession() -> AccountSession {
        AccountSession(accountID: accountID, accessToken: "demo-access", refreshToken: "demo-refresh",
                       expiresAt: Date().addingTimeInterval(3_600))
    }

    private func validate(email: String) throws {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, parts[1].contains("."),
              !email.contains(where: { $0.isWhitespace }) else { throw AccountError.invalidEmail }
    }

    private func validate(code: String) throws {
        guard (6...10).contains(code.count), code.allSatisfy({ $0.isASCII && $0.isNumber })
        else { throw AccountError.invalidCode }
    }
}
