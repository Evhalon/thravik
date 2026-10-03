import Foundation
import Observation
import RedentKit

@MainActor @Observable
public final class AccountModel {
    public internal(set) var session: AccountSession?
    public private(set) var isBusy = false
    public internal(set) var awaitingEmailCode = false
    public internal(set) var awaitingRecoveryCode = false
    public internal(set) var awaitingNewPassword = false
    public internal(set) var errorMessage: String?
    public let isConfigured: Bool
    let authentication: (any AccountAuthenticating)?
    let sessions: any AccountSessionStoring
    private let google: (any GoogleAccountAuthenticating)?
    private var attemptedIdentityRefresh = false
    var recoverySession: AccountSession?
    @ObservationIgnored public var onSessionChanged: (@MainActor (AccountSession?) -> Void)?
    @ObservationIgnored public var presentGoogle: (@MainActor (URL) async throws -> URL)?

    public init(authentication: (any AccountAuthenticating)?, sessions: any AccountSessionStoring,
                google: (any GoogleAccountAuthenticating)? = nil) {
        self.authentication = authentication
        self.sessions = sessions
        self.google = google
        isConfigured = authentication != nil
    }

    public func restore() async {
        guard !isBusy, let authentication else { return }
        await perform {
            guard let stored = try await sessions.load() else { return }
            session = stored
            onSessionChanged?(stored)
            let tokenNeedsRefresh = stored.expiresAt <= Date().addingTimeInterval(60)
            let identityNeedsRefresh = stored.email == nil && !attemptedIdentityRefresh
            guard tokenNeedsRefresh || identityNeedsRefresh else { return }
            if identityNeedsRefresh { attemptedIdentityRefresh = true }
            let refreshed: AccountSession
            do { refreshed = try await authentication.refresh(session: stored) }
            catch {
                if identityNeedsRefresh && !tokenNeedsRefresh { return }
                throw error
            }
            guard refreshed.accountID == stored.accountID else { throw AccountError.invalidResponse }
            try await sessions.save(refreshed)
            session = refreshed
            onSessionChanged?(refreshed)
        }
    }

    public func requestEmailCode(email: String) async {
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isBusy, session == nil, !address.isEmpty, let authentication else { return }
        await perform {
            resetRecovery()
            try await authentication.requestEmailCode(email: address)
            awaitingEmailCode = true
        }
    }

    public func cancelEmailCode() {
        guard !isBusy, awaitingEmailCode else { return }
        awaitingEmailCode = false
        errorMessage = nil
    }

    public func verifyEmailCode(email: String, code: String) async {
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isBusy, session == nil, awaitingEmailCode, !address.isEmpty, !token.isEmpty,
              let authentication else { return }
        await perform {
            let signedIn = try await authentication.verifyEmailCode(email: address, code: token)
            resetRecovery()
            try await sessions.save(signedIn)
            session = signedIn
            onSessionChanged?(signedIn)
            awaitingEmailCode = false
        }
    }

    public func signInWithGoogle() async {
        guard !isBusy, session == nil, let google, let presentGoogle else { return }
        await perform {
            do {
                let url = try await google.authorizationURL()
                let callback = try await presentGoogle(url)
                let signedIn = try await google.completeGoogleSignIn(callback: callback)
                resetRecovery()
                try await sessions.save(signedIn)
                session = signedIn
                onSessionChanged?(signedIn)
                awaitingEmailCode = false
            } catch {
                await google.cancelGoogleSignIn()
                throw error
            }
        }
    }

    public func signOut() async {
        guard !isBusy, let authentication, let session else { return }
        await perform {
            try await sessions.clear()
            self.session = nil
            resetRecovery()
            onSessionChanged?(nil)
            awaitingEmailCode = false
            try await authentication.signOut(session: session)
        }
    }

    func perform(_ action: () async throws -> Void) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do { try await action() }
        catch is CancellationError { }
        catch let error as AccountError { errorMessage = AccountModelErrorMessage.message(for: error) }
        catch let error as VaultError { errorMessage = AccountModelErrorMessage.message(for: error) }
        catch { errorMessage = "Account operation failed. Try again." }
    }

    func resetRecovery() {
        recoverySession = nil
        awaitingRecoveryCode = false
        awaitingNewPassword = false
    }
}
