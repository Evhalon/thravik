import Foundation
import RedentKit

public protocol PasswordEnvelopeStoring: Sendable {
    func load(session: AccountSession) async throws -> PasswordKeyEnvelope?
    /// Returns true for a first write or identical retry; never replaces an envelope.
    func saveIfAbsent(_ envelope: PasswordKeyEnvelope, session: AccountSession) async throws -> Bool
    func replace(_ envelope: PasswordKeyEnvelope, expected: PasswordKeyEnvelope,
                 claimKey: Data, session: AccountSession) async throws -> Bool
}

public extension PasswordEnvelopeStoring {
    func replace(_ envelope: PasswordKeyEnvelope, expected: PasswordKeyEnvelope,
                 claimKey: Data, session: AccountSession) async throws -> Bool { throw SyncError.unavailable }
}
