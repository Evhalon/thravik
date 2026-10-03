import Foundation
import Testing
import RedentKit
@testable import RedentSync

struct WorkspaceSyncPublisherTests {
    @Test func republishSkipsUnchangedWorkspaceAndRoundTrips() async throws {
        let account = UUID()
        let replica = MemoryWorkspaceReplica()
        let publisher = WorkspaceSyncPublisher(accountID: account, replica: replica)
        let key = SyncCryptography().makeRootKey()
        let device = UUID(uuid: (8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8))
        let spaceID = UUID(uuid: (9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9))
        let space = BrowserSpace(id: spaceID, name: "Studio")
        let url = try #require(URL(string: "https://studio.example/home"))
        var tab = TabSnapshot(url: url, title: "Home")
        tab.spaceID = spaceID
        let session = BrowserSession(tabs: [tab], selectedTabID: tab.id, spaces: [space], selectedSpaceID: spaceID)
        try await publisher.publish(session, deviceID: device, rootKey: key)
        let written = await replica.enqueued
        let cipher = SyncMutationCipher()
        let before = try await plaintext(of: replica, cipher: cipher, key: key)
        try await publisher.publish(session, deviceID: device, rootKey: key)
        let after = try await plaintext(of: replica, cipher: cipher, key: key)
        #expect(before == after)
        #expect(await replica.enqueued == written)
        let replacements = await replica.replacements
        #expect(replacements == [String]())

        let snapshot = try await WorkspaceSyncReader(accountID: account)
            .snapshot(from: replica, deviceID: device, rootKey: key)
        let local = WorkspaceSyncMerge.apply(local: BrowserSession(), snapshot: snapshot)
        #expect(local.session.spaces.contains { $0.name == "Studio" })
        #expect(local.remoteTabs.isEmpty)
        var elsewhere = snapshot
        elsewhere.localDeviceID = UUID(uuid: (7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7))
        let other = WorkspaceSyncMerge.apply(local: BrowserSession(), snapshot: elsewhere)
        #expect(other.remoteTabs.map(\.title) == ["Home"])
        #expect(other.session.tabs.allSatisfy { $0.title != "Home" })
    }

    private func plaintext(of replica: MemoryWorkspaceReplica, cipher: SyncMutationCipher, key: Data) async throws -> [String] {
        var values: [String] = []
        for mutation in await replica.mutations() {
            let data = try cipher.decrypt(mutation, rootKey: key)
            values.append(String(decoding: data, as: UTF8.self))
        }
        return values.sorted()
    }
}

private actor MemoryWorkspaceReplica: AuthenticatedSyncStoring {
    private var outbox: [SyncMutation] = []
    private(set) var enqueued = 0
    private(set) var replaced = 0
    private(set) var replacements: [String] = []

    func enqueue(_ mutation: SyncMutation) {
        enqueued += 1
        outbox.append(mutation)
    }

    func replacePending(_ mutation: SyncMutation, with replacement: SyncMutation?) {
        replaced += 1
        replacements.append(mutation.identity.collection)
        outbox.removeAll { $0.id == mutation.id }
        if let replacement { outbox.append(replacement) }
    }

    func pending(accountID: UUID, limit: Int) -> [SyncMutation] {
        Array(outbox.filter { $0.identity.accountID == accountID }.prefix(limit))
    }

    func acknowledge(_ record: SyncRemoteRecord) {
        outbox.removeAll { $0.id == record.mutation.id }
    }

    func cursor(accountID: UUID) -> Int64 { 0 }

    func apply(_ page: SyncPage, accountID: UUID) {}

    func mutations() -> [SyncMutation] { outbox }

    func records(accountID: UUID) -> [SyncRemoteRecord] { [] }
}
