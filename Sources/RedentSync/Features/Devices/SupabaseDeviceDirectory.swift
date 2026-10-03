import Foundation
import RedentKit

public struct SupabaseDeviceDirectory: SyncDeviceDirectorying {
    private let rpc: SupabaseDeviceRPC

    public init(configuration: SupabaseConfiguration,
                transport: any SupabaseHTTPTransport = URLSessionSupabaseTransport()) {
        rpc = SupabaseDeviceRPC(configuration: configuration, transport: transport)
    }

    public func bootstrap(_ identity: SyncDevicePublicIdentity, credential: Data, session: AccountSession) async throws {
        _ = try await rpc.call("sync_device_bootstrap", body: DeviceBody(identity: identity, credential: credential),
                               session: session)
    }

    public func enroll(_ identity: SyncDevicePublicIdentity, credential: Data, expiresAt: Date,
                       session: AccountSession) async throws {
        _ = try await rpc.call("sync_device_enroll",
                               body: DeviceBody(identity: identity, credential: credential, expiresAt: expiresAt),
                               session: session)
    }

    public func list(session: AccountSession) async throws -> [SyncDeviceRecord] {
        let data = try await rpc.call("sync_device_list", body: Empty(), session: session)
        let rows = try JSONDecoder().decode([ListedDevice].self, from: data)
        return try rows.map { try $0.record() }
    }

    public func approve(_ approval: SyncDeviceApproval, credential: Data, session: AccountSession) async throws {
        _ = try await rpc.call("sync_device_approve", body: ApproveBody(approval: approval, credential: credential),
                               session: session)
    }

    public func envelope(deviceID: UUID, credential: Data, session: AccountSession) async throws -> SyncDeviceApproval? {
        let data = try await rpc.call("sync_device_envelope", body: EnvelopeQuery(deviceID: deviceID, credential: credential),
                                      session: session)
        guard data != Data("null".utf8) else { return nil }
        return try JSONDecoder().decode(EnvelopeRow.self, from: data).approval()
    }

    public func revoke(deviceID: UUID, approverID: UUID, credential: Data, session: AccountSession) async throws {
        _ = try await rpc.call("sync_device_revoke",
                               body: RevokeBody(deviceID: deviceID, approverID: approverID, credential: credential),
                               session: session)
    }

    public func publishClaim(_ claimKey: Data, session: AccountSession) async throws {
        _ = try await rpc.call("sync_recovery_claim_publish", body: ClaimKeyBody(claimKey: claimKey), session: session)
    }

    public func claim(deviceID: UUID, credential: Data, claimKey: Data, session: AccountSession) async throws {
        _ = try await rpc.call("sync_device_claim",
                               body: ClaimBody(deviceID: deviceID, credential: credential, claimKey: claimKey),
                               session: session)
    }

    private struct Empty: Encodable {}
}
