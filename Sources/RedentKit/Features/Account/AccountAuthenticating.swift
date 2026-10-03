import Foundation

public protocol AccountAuthenticating: Sendable {
    func requestEmailCode(email: String) async throws
    func verifyEmailCode(email: String, code: String) async throws -> AccountSession
    func signInWithPassword(email: String, password: String) async throws -> AccountSession
    func requestPasswordRecovery(email: String) async throws
    func verifyPasswordRecoveryCode(email: String, code: String) async throws -> AccountSession
    func updatePassword(session: AccountSession, password: String) async throws
    func refresh(session: AccountSession) async throws -> AccountSession
    func signOut(session: AccountSession) async throws
}

public extension AccountAuthenticating {
    func signInWithPassword(email: String, password: String) async throws -> AccountSession {
        throw AccountError.unsupportedOperation
    }

    func requestPasswordRecovery(email: String) async throws {
        throw AccountError.unsupportedOperation
    }

    func verifyPasswordRecoveryCode(email: String, code: String) async throws -> AccountSession {
        throw AccountError.unsupportedOperation
    }

    func updatePassword(session: AccountSession, password: String) async throws {
        throw AccountError.unsupportedOperation
    }
}
