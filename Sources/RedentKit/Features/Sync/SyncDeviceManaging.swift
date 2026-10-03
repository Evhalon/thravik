import Foundation

public protocol SyncDeviceManaging: Sendable {
    func prepare() async throws -> [SyncDeviceSummary]
    func publishClaim(recoveryCode: String) async throws
    func approve(recipientID: UUID) async throws -> [SyncDeviceSummary]
    func importRootKey() async throws -> [SyncDeviceSummary]
    func revoke(deviceID: UUID) async throws -> [SyncDeviceSummary]
    func claim(recoveryCode: String) async throws -> [SyncDeviceSummary]
}
