import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
struct DeviceMembershipModelTests {
    @Test func backendFailureCannotEnableCloudSync() async {
        let model = DeviceMembershipModel(manager: DeviceManagerFake(error: .backendNotConfigured))
        await #expect(throws: SyncError.backendNotConfigured) { try await model.prepareForSync() }
        #expect(model.devices.isEmpty)
        #expect(!model.isBusy)
        await model.refresh()
        #expect(model.message == "Cloud sync is not configured on the server. Contact support.")
    }

    @Test func pendingLocalDeviceCannotEnableCloudSync() async {
        let local = SyncDeviceSummary(id: UUID(), status: .pending, fingerprint: "local", isLocal: true)
        let remote = SyncDeviceSummary(id: UUID(), status: .approved, fingerprint: "remote", isLocal: false)
        let model = DeviceMembershipModel(manager: DeviceManagerFake(devices: [local, remote]))
        await #expect(throws: SyncError.deviceAuthenticationRequired) { try await model.prepareForSync() }
        #expect(model.devices == [local, remote])
        #expect(!model.isBusy)
    }

    @Test func approvedLocalDeviceEnablesCloudSync() async throws {
        let local = SyncDeviceSummary(id: UUID(), status: .approved, fingerprint: "local", isLocal: true)
        let model = DeviceMembershipModel(manager: DeviceManagerFake(devices: [local]))
        try await model.prepareForSync()
        #expect(model.devices == [local])
        #expect(!model.isBusy)
    }
}

private struct DeviceManagerFake: SyncDeviceManaging {
    var devices: [SyncDeviceSummary] = []
    var error: SyncError?

    func prepare() throws -> [SyncDeviceSummary] {
        if let error { throw error }
        return devices
    }

    func publishClaim(recoveryCode: String) async throws {}
    func approve(recipientID: UUID) throws -> [SyncDeviceSummary] { try prepare() }
    func importRootKey() throws -> [SyncDeviceSummary] { try prepare() }
    func revoke(deviceID: UUID) throws -> [SyncDeviceSummary] { try prepare() }
    func claim(recoveryCode: String) throws -> [SyncDeviceSummary] { try prepare() }
}
