import Foundation
import RedentKit

/// A save the user has not answered yet, as the prompt needs to render it.
public struct CredentialSaveRequest: Identifiable, Sendable {
    public enum Kind: Sendable { case new, updatedPassword }

    public let id = UUID()
    public let candidate: CredentialCandidate
    public let kind: Kind
    /// The entry this replaces, kept whole so an update kicks over neither the
    /// creation date nor the ranking that orders the autofill list.
    public let existing: Credential?

    public var existingID: UUID? { existing?.id }

    public init(candidate: CredentialCandidate, kind: Kind, existing: Credential?) {
        self.candidate = candidate
        self.kind = kind
        self.existing = existing
    }

    /// The entry to write when the user accepts.
    public var resolvedCredential: Credential {
        Credential(
            id: existing?.id ?? UUID(),
            origin: candidate.origin,
            username: candidate.username,
            password: candidate.password,
            createdAt: existing?.createdAt ?? .now,
            lastUsedAt: existing?.lastUsedAt,
            useCount: existing?.useCount ?? 0
        )
    }
}
