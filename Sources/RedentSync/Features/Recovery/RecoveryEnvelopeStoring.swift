import Foundation
import RedentKit

public protocol RecoveryEnvelopeStoring: Sendable {
    func load(session: AccountSession) async throws -> SyncEncryptedEnvelope?
    /// Returns true for the first write or an identical retry; never replaces another envelope.
    func saveIfAbsent(_ envelope: SyncEncryptedEnvelope, session: AccountSession) async throws -> Bool
}
