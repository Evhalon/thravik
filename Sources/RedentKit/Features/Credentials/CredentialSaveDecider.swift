import Foundation

/// What should happen to a login the page just submitted.
public enum CredentialSaveOutcome: Equatable, Sendable {
    /// We already hold exactly this login; only its usage stamp is worth touching.
    case alreadyStored(id: UUID)
    case save(CredentialCandidate)
    case update(existing: Credential, candidate: CredentialCandidate)
}

/// Decides whether a submitted login is worth saving, and against which entry.
///
/// Change-password forms are the hard case. They carry a new password but
/// almost never a username field, so matching by the submitted string alone
/// files the change as a brand-new login and leaves the real entry holding a
/// password that no longer opens anything.
public enum CredentialSaveDecider {
    /// - Parameters:
    ///   - stored: credentials for the candidate's origin, most-recently-used first.
    ///   - identityHint: the username last seen on this origin, if any.
    public static func outcome(
        for candidate: CredentialCandidate,
        stored: [Credential],
        identityHint: String = ""
    ) -> CredentialSaveOutcome? {
        guard !candidate.password.isEmpty else { return nil }
        let identity = candidate.username.isEmpty ? identityHint : candidate.username
        guard let match = match(for: candidate, identity: identity, stored: stored) else {
            return .save(candidate.named(identity))
        }
        guard match.password != candidate.password else { return .alreadyStored(id: match.id) }
        return .update(existing: match, candidate: candidate.named(match.username))
    }

    private static func match(
        for candidate: CredentialCandidate, identity: String, stored: [Credential]
    ) -> Credential? {
        if !identity.isEmpty {
            // Sites echo back whatever casing the user typed; an email is the
            // same account either way.
            return stored.first { $0.username.caseInsensitiveCompare(identity) == .orderedSame }
        }
        // Nothing names the user, so only a password change is safe to attribute:
        // it is by definition a second password for an account we already hold,
        // and the most-recently-used entry is the session the page is in. The
        // prompt still shows that username before anything is written.
        guard candidate.isPasswordChange else { return nil }
        return stored.first
    }
}
