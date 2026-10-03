import CryptoKit
import Foundation
import RedentKit

actor WorkspaceSyncPublisher {
    private let writer: WorkspaceSyncMutation
    private var retiredSpaces: Set<UUID> = []
    private var retiredGroups: Set<UUID> = []
    private var knownSpaces: Set<UUID> = []
    private var knownGroups: Set<UUID> = []
    private var lastCatalog: SHA256.Digest?
    private var lastTabs: SHA256.Digest?

    init(accountID: UUID, replica: any AuthenticatedSyncStoring) {
        writer = WorkspaceSyncMutation(accountID: accountID, replica: replica)
    }

    func absorb(_ catalog: SyncSpaceCatalog) {
        let liveSpaces = Set(catalog.spaces.map(\.id))
        retiredSpaces.formUnion(catalog.retiredSpaceIDs)
        retiredSpaces.subtract(liveSpaces)
        knownSpaces = liveSpaces
        let liveGroups = Set(catalog.groups.map(\.id))
        retiredGroups.formUnion(catalog.retiredGroupIDs)
        retiredGroups.subtract(liveGroups)
        knownGroups = liveGroups
    }

    func publish(_ session: BrowserSession, deviceID: UUID, rootKey: Data) async throws {
        retireMissing(from: session)
        try await publishCatalog(session, rootKey: rootKey)
        try await publishTabs(session, deviceID: deviceID, rootKey: rootKey)
    }

    private func retireMissing(from session: BrowserSession) {
        let spaces = Set(session.spaces.map(\.id))
        retiredSpaces.formUnion(knownSpaces.subtracting(spaces))
        retiredSpaces.subtract(spaces)
        knownSpaces = spaces
        let groups = Set(session.groups.map(\.id))
        retiredGroups.formUnion(knownGroups.subtracting(groups))
        retiredGroups.subtract(groups)
        knownGroups = groups
    }

    private func publishCatalog(_ session: BrowserSession, rootKey: Data) async throws {
        let catalog = SyncSpaceCatalog(session: session, retiredSpaceIDs: sorted(retiredSpaces),
                                       retiredGroupIDs: sorted(retiredGroups))
        var encoded = try encode(catalog)
        defer { encoded.resetBytes(in: 0..<encoded.count) }
        let digest = SHA256.hash(data: encoded)
        guard digest != lastCatalog else { return }
        try await writer.enqueue(collection: "workspace", recordID: SyncSpaceCatalog.recordID,
                                 plaintext: encoded, rootKey: rootKey)
        lastCatalog = digest
    }

    private func publishTabs(_ session: BrowserSession, deviceID: UUID, rootKey: Data) async throws {
        var encoded = try encode(SyncDeviceTabs(session: session, deviceID: deviceID))
        defer { encoded.resetBytes(in: 0..<encoded.count) }
        let digest = SHA256.hash(data: encoded)
        guard digest != lastTabs else { return }
        try await writer.enqueue(collection: "device_tabs", recordID: deviceID, plaintext: encoded, rootKey: rootKey)
        lastTabs = digest
    }

    private func encode(_ value: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }

    private func sorted(_ ids: Set<UUID>) -> [UUID] {
        ids.sorted { $0.uuidString < $1.uuidString }
    }
}
