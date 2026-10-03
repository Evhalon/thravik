import Foundation

public enum SyncError: Error, Sendable, Equatable {
    case invalidMutation
    case invalidResponse
    case accountMismatch
    case revisionConflict
    case mutationCollision
    case unavailable
    case backendNotConfigured
    case cursorExpired
    case alreadyRunning
    case unauthorized
    case quotaExceeded
    case rateLimited
    case deviceAlreadyRegistered
    case deviceAuthenticationRequired
    case deviceRejected
    case deviceExpired
    case recoveryClaimRejected
}
