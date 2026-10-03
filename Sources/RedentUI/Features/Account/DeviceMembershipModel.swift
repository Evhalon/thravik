import Foundation
import Observation
import RedentKit

@MainActor @Observable
public final class DeviceMembershipModel {
    public private(set) var devices: [SyncDeviceSummary] = []
    public private(set) var isBusy = false
    public private(set) var message: String?
    public var recoveryCode = ""
    private let manager: any SyncDeviceManaging

    public init(manager: any SyncDeviceManaging) { self.manager = manager }

    public func refresh() async { await run { devices = try await manager.prepare() } }
    public func approve(_ id: UUID) async { await run { devices = try await manager.approve(recipientID: id) } }
    public func importKey() async { await run { devices = try await manager.importRootKey() } }
    public func revoke(_ id: UUID) async { await run { devices = try await manager.revoke(deviceID: id) } }

    public func claim() async {
        let code = recoveryCode
        await run {
            devices = try await manager.claim(recoveryCode: code)
            recoveryCode = ""
        }
    }

    public func authorize(recoveryCode: String) async throws {
        devices = try await manager.claim(recoveryCode: recoveryCode)
    }

    public func prepareForSync() async throws {
        guard !isBusy else { throw SyncError.alreadyRunning }
        isBusy = true
        defer { isBusy = false }
        devices = try await manager.prepare()
        guard devices.contains(where: { $0.isLocal && $0.status == .approved }) else {
            throw SyncError.deviceAuthenticationRequired
        }
    }

    private func run(_ body: () async throws -> Void) async {
        guard !isBusy else { return }
        isBusy = true
        message = nil
        defer { isBusy = false }
        do { try await body() }
        catch is CancellationError { }
        catch SyncError.alreadyRunning { }
        catch SyncError.backendNotConfigured { message = "Cloud sync is not configured on the server. Contact support." }
        catch { message = "Device authorization failed. Try again." }
    }
}
