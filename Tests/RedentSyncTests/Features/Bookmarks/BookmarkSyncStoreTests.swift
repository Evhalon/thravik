import Foundation
import RedentKit
import Testing
@testable import RedentSync

struct BookmarkSyncStoreTests {
    @Test func secondDeviceRestoresEditsAndDeletions() async throws {
        let account = UUID()
        let rootKey = Data(repeating: 9, count: 32)
        let server = BookmarkSyncTestServer()
        let first = try await makeDevice(account: account, server: server, key: rootKey)
        let second = try await makeDevice(account: account, server: server, key: rootKey)
        let url = try #require(URL(string: "https://sync.example/page"))
        let initial = Bookmark(url: url, title: "First")

        await first.sync.save(initial)
        _ = try await first.sync.synchronize()
        _ = try await second.sync.synchronize()
        #expect(await second.store.all(in: nil) == [initial])

        var edited = initial
        edited.title = "Updated"
        await second.sync.save(edited)
        _ = try await second.sync.synchronize()
        _ = try await first.sync.synchronize()
        #expect(await first.store.all(in: nil) == [edited])

        await second.sync.delete(initial.id)
        _ = try await second.sync.synchronize()
        _ = try await first.sync.synchronize()
        #expect(await first.store.all(in: nil).isEmpty)
    }

    @Test func mergeDeduplicatesNormalizedURLsBeforePublishing() async throws {
        let account = UUID()
        let server = BookmarkSyncTestServer()
        let key = Data(repeating: 9, count: 32)
        let first = try await makeDevice(account: account, server: server, key: key)
        let second = try await makeDevice(account: account, server: server, key: key)
        let original = Bookmark(url: try #require(URL(string: "https://sync.example/page/")))
        let duplicate = Bookmark(url: try #require(URL(string: "https://sync.example/page?utm_source=test")))
        #expect(await first.sync.merge([original, duplicate]) == 1)
        _ = try await first.sync.synchronize()
        _ = try await second.sync.synchronize()
        #expect(await second.store.all(in: nil) == [original])
    }

    @Test func emptyFoldersSyncAndDeleteAcrossDevices() async throws {
        let account = UUID()
        let server = BookmarkSyncTestServer()
        let key = Data(repeating: 9, count: 32)
        let first = try await makeDevice(account: account, server: server, key: key)
        let second = try await makeDevice(account: account, server: server, key: key)
        let folder = BookmarkFolder(path: ["Work"], spaceID: nil)
        await first.sync.saveFolder(folder)
        #expect(await first.sync.writeError == nil)
        #expect(await first.store.folders(in: nil) == [folder])
        _ = try await first.sync.synchronize()
        _ = try await second.sync.synchronize()
        #expect(await second.store.folders(in: nil) == [folder])
        await second.sync.deleteFolder(folder)
        _ = try await second.sync.synchronize()
        _ = try await first.sync.synchronize()
        #expect(await first.store.folders(in: nil).isEmpty)
    }

    private func makeDevice(account: UUID, server: BookmarkSyncTestServer, key: Data) async throws -> TestDevice {
        let secrets = SyncDeviceSecrets(deviceID: UUID(), agreementPrivateKey: Data([1]),
                                        signingPrivateKey: Data([2]), credential: Data([3]))
        let keys = BookmarkSyncTestKeys(account: account, key: key)
        let deviceKeys = BookmarkSyncTestDeviceKeys(account: account, device: secrets)
        let sessions = BookmarkSyncTestSessions(account: account)
        let replica = BookmarkSyncTestReplica()
        let store = BookmarkSyncTestBookmarkStore()
        let dependencies = BookmarkSyncDependencies(replica: replica, keys: keys, deviceKeys: deviceKeys,
            transport: server, sessions: sessions)
        let sync = BookmarkSyncStore(accountID: account, dependencies: dependencies, bookmarks: store)
        return TestDevice(sync: sync, store: store, replica: replica)
    }
}

private struct TestDevice {
    let sync: BookmarkSyncStore
    let store: BookmarkSyncTestBookmarkStore
    let replica: BookmarkSyncTestReplica
}
