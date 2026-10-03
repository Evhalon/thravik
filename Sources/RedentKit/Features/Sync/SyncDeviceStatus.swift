import Foundation

public enum SyncDeviceStatus: String, Sendable, Codable, Equatable {
    case pending
    case approved
    case revoked
}
