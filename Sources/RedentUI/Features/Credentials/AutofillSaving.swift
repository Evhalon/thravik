import Foundation
import RedentKit

/// The other half of autofill: deciding whether a submitted login is worth
/// saving, and writing it into the Space the tab was browsing in.
extension AutofillCoordinator {
    /// The page submitted a login, or changed a password. Offer to save it
    /// unless we already hold exactly that entry.
    public func credentialSubmitted(_ candidate: CredentialCandidate) async {
        guard isEnabled else { return }
        let generation = saveGeneration
        captureIdentity(candidate.username)
        let stored = (try? await store.credentials(for: candidate.origin)) ?? []
        guard isEnabled, saveGeneration == generation else { return }
        let outcome = CredentialSaveDecider.outcome(
            for: candidate, stored: stored, identityHint: lastUsername
        )
        switch outcome {
        case nil:
            return
        case .alreadyStored(let id):
            try? await store.markUsed(id)
        case .save(let resolved):
            pendingSave = CredentialSaveRequest(
                candidate: resolved, kind: .new, existing: nil
            )
        case .update(let existing, let resolved):
            pendingSave = CredentialSaveRequest(
                candidate: resolved, kind: .updatedPassword, existing: existing
            )
        }
    }

    public func confirmPendingSave() async {
        guard let request = pendingSave, !isSavingPassword else { return }
        isSavingPassword = true
        saveErrorMessage = nil
        defer { isSavingPassword = false }
        let generation = saveGeneration
        let credential = resolvedSaveCredential ?? request.resolvedCredential
        resolvedSaveCredential = credential
        do {
            try await store.save(credential)
            guard saveGeneration == generation, pendingSave?.id == request.id else { return }
            pendingSave = nil
            logger.notice("autofill: password saved")
            await refreshSuggestions(for: credential.origin)
        } catch {
            guard saveGeneration == generation, pendingSave?.id == request.id else { return }
            if error as? PasswordStorageError == .providerChanged {
                pendingSave = nil
                return
            }
            saveErrorMessage = "Password could not be saved. Unlock your vault and try again."
            logger.error("autofill: password save failed")
        }
    }

    public func dismissPendingSave() { pendingSave = nil }
}
