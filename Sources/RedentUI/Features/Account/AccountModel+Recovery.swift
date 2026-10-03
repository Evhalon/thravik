import Foundation
import RedentKit

extension AccountModel {
    public func signInWithPassword(email: String, password: String) async {
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isBusy, session == nil, !address.isEmpty, !password.isEmpty,
              let authentication else { return }
        await perform {
            let signedIn = try await authentication.signInWithPassword(email: address, password: password)
            resetRecovery()
            awaitingEmailCode = false
            try await sessions.save(signedIn)
            session = signedIn
            onSessionChanged?(signedIn)
        }
    }

    public func requestPasswordRecovery(email: String) async {
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isBusy, session == nil, !address.isEmpty, let authentication else { return }
        await perform {
            awaitingEmailCode = false
            resetRecovery()
            try await authentication.requestPasswordRecovery(email: address)
            awaitingRecoveryCode = true
        }
    }

    public func verifyPasswordRecoveryCode(email: String, code: String) async {
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isBusy, session == nil, awaitingRecoveryCode, !address.isEmpty, !token.isEmpty,
              let authentication else { return }
        await perform {
            let pending = try await authentication.verifyPasswordRecoveryCode(email: address, code: token)
            recoverySession = pending
            awaitingRecoveryCode = false
            awaitingNewPassword = true
        }
    }

    public func completePasswordRecovery(password: String, confirmation: String) async {
        guard !isBusy, session == nil, awaitingNewPassword, let pending = recoverySession,
              let authentication else { return }
        guard password == confirmation else {
            errorMessage = "Passwords do not match."
            return
        }
        await perform {
            try await authentication.updatePassword(session: pending, password: password)
            try await sessions.save(pending)
            session = pending
            recoverySession = nil
            awaitingNewPassword = false
            onSessionChanged?(pending)
        }
    }

    public func cancelPasswordRecovery() {
        guard !isBusy else { return }
        resetRecovery()
        errorMessage = nil
    }
}
