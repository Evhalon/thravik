import Foundation
import RedentKit

struct SupabaseRPCFailure: Decodable {
    let code: String?
    let message: String?

    static func error(data: Data, status: Int) -> SyncError? {
        guard !(200..<300).contains(status),
              let failure = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        if failure.code == "PGRST202" || failure.code == "PGRST205" { return .backendNotConfigured }
        switch failure.message {
        case "foundation_quota_reached": return .quotaExceeded
        case "mutation_payload_mismatch": return .mutationCollision
        case "device_authentication_required": return .deviceAuthenticationRequired
        case "device_rejected": return .deviceRejected
        case "device_expired": return .deviceExpired
        case "device_already_registered": return .deviceAlreadyRegistered
        case "recovery_claim_rejected": return .recoveryClaimRejected
        case "authentication_required": return .unauthorized
        default: return nil
        }
    }
}
