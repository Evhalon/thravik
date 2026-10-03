import Foundation

public struct SyncDeviceSummary: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let status: SyncDeviceStatus
    public let fingerprint: String
    public let isLocal: Bool

    public init(id: UUID, status: SyncDeviceStatus, fingerprint: String, isLocal: Bool) {
        self.id = id
        self.status = status
        self.fingerprint = fingerprint
        self.isLocal = isLocal
    }
}
