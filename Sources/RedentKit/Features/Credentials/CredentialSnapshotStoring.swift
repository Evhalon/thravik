import Foundation

/// Cloud projection commits an entire account vault once, without per-login rewrites.
public protocol CredentialSnapshotStoring: CredentialStoring {
    func applySnapshot(_ credentials: [Credential]) async throws
}
