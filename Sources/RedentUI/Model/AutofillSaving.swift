import Foundation
import RedentKit

/// The other half of autofill: deciding whether a submitted login is worth
/// saving, and writing it into the Space the tab was browsing in.
extension AutofillCoordinator {
    /// The page submitted a login, or changed a password. Offer to save it
    /// unless we already hold exactly that entry.
    public func credentialSubmitted(_ candidate: CredentialCandidate) async {
        guard isEnabled else { return }
        captureIdentity(candidate.username)
        let stored = (try? await store.credentials(for: candidate.origin, in: spaceID)) ?? []
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
                candidate: resolved, kind: .new, existing: nil, spaceID: spaceID
            )
        case .update(let existing, let resolved):
            pendingSave = CredentialSaveRequest(
                candidate: resolved, kind: .updatedPassword, existing: existing, spaceID: spaceID
            )
        }
    }

    public func confirmPendingSave() async {
        guard let request = pendingSave else { return }
        pendingSave = nil
        let credential = request.resolvedCredential
        do {
            try await store.save(credential)
            logger.notice("autofill: saved \(credential.redactedDescription)")
            await refreshSuggestions(for: credential.origin)
        } catch {
            logger.error("autofill: save failed — \(String(describing: error))")
        }
    }

    public func dismissPendingSave() { pendingSave = nil }
}
