import Foundation

public protocol RecoveryClaimPublishing: Sendable {
    func publish(claimKey: Data, session: AccountSession) async throws
}
