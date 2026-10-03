import Foundation
import RedentKit

struct WorkspaceSyncReader {
    let accountID: UUID
    private let cipher = SyncMutationCipher()

    func snapshot(from replica: any AuthenticatedSyncStoring, deviceID: UUID, rootKey: Data) async throws
        -> WorkspaceSyncSnapshot {
        let records = try await replica.records(accountID: accountID)
        let pending = try await replica.pending(accountID: accountID, limit: 10_000)
        var catalog: SyncSpaceCatalog?
        var devices: [UUID: SyncDeviceTabs] = [:]
        for record in records { try project(record.mutation, rootKey: rootKey, catalog: &catalog, devices: &devices) }
        for mutation in pending { try project(mutation, rootKey: rootKey, catalog: &catalog, devices: &devices) }
        return WorkspaceSyncSnapshot(catalog: catalog, deviceTabs: Array(devices.values), localDeviceID: deviceID)
    }

    private func project(_ mutation: SyncMutation, rootKey: Data, catalog: inout SyncSpaceCatalog?,
                         devices: inout [UUID: SyncDeviceTabs]) throws {
        guard mutation.identity.accountID == accountID else { throw SyncError.accountMismatch }
        guard mutation.identity.collection == "workspace" || mutation.identity.collection == "device_tabs" else { return }
        var plaintext = try cipher.decrypt(mutation, rootKey: rootKey)
        defer { plaintext.resetBytes(in: 0..<plaintext.count) }
        if mutation.identity.collection == "workspace" {
            guard let value = try? JSONDecoder().decode(SyncSpaceCatalog.self, from: plaintext),
                  value.schemaVersion == SyncSpaceCatalog.schemaVersion else { throw SyncError.invalidResponse }
            catalog = value
            return
        }
        guard let tabs = try? JSONDecoder().decode(SyncDeviceTabs.self, from: plaintext),
              tabs.schemaVersion == SyncDeviceTabs.schemaVersion,
              tabs.deviceID == mutation.identity.recordID else { throw SyncError.invalidResponse }
        devices[tabs.deviceID] = tabs
    }
}
