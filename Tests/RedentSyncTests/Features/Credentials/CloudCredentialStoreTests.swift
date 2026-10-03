import Foundation
import RedentKit
@testable import RedentSync
import Testing

struct CloudCredentialStoreTests {
    @Test func encryptedIntentSurvivesKeychainFailure() async throws {
        let fixture = CloudCredentialFixtures()
        let store = await fixture.store()
        let credential = Credential(origin: Origin(scheme: "https", host: "example.com"),
                                    username: "person", password: "secret-password")
        await fixture.setFailSave(true)
        await #expect(throws: SyncError.unavailable) { try await store.save(credential) }
        let pending = await fixture.pending(accountID: fixture.accountID, limit: 100)
        #expect(pending.count == 1)
        #expect(!String(decoding: pending[0].encryptedPayload, as: UTF8.self).contains("secret-password"))
        await fixture.setFailSave(false)
        #expect(try await store.allCredentials() == [credential])
        try await store.save(credential)
        #expect(await fixture.mutations.count == 1)
    }

    @Test func accountMismatchRejectsWrites() async throws {
        let fixture = CloudCredentialFixtures()
        let store = await fixture.store()
        await fixture.setMismatch()
        await #expect(throws: SyncError.accountMismatch) { try await store.delete(UUID()) }
        #expect(await fixture.mutations.isEmpty)
    }

    @Test func deletionIsDurableAndUploads() async throws {
        let fixture = CloudCredentialFixtures()
        let store = await fixture.store()
        let credential = Credential(origin: Origin(scheme: "https", host: "example.com"),
                                    username: "person", password: "secret")
        try await store.save(credential)
        let session = try #require(await fixture.load())
        #expect(try await store.synchronize(session: session).uploaded == 1)
        try await store.delete(credential.id)
        #expect(try await store.allCredentials().isEmpty)
        #expect(try await store.synchronize(session: session).uploaded == 1)
        #expect(await fixture.remote.first?.mutation.isDeleted == true)
    }
    @Test func incomingConflictPreservesLocalPassword() async throws {
        let fixture = CloudCredentialFixtures()
        let store = await fixture.store()
        let credential = Credential(origin: Origin(scheme: "https", host: "example.com"),
                                    username: "person", password: "local-secret")
        try await store.save(credential)
        let session = try #require(await fixture.load())
        let incoming = Credential(id: credential.id, origin: credential.origin,
                                  username: "person", password: "remote-secret")
        let cipher = SyncMutationCipher()
        let request = SyncWriteRequest(identity: .init(accountID: session.accountID,
            collection: "credentials", recordID: incoming.id), expectedRevision: 0,
            plaintext: try JSONEncoder().encode(CloudCredentialPayload(incoming)))
        let mutation = try cipher.encrypt(request, rootKey: Data(repeating: 7, count: 32))
        await fixture.setIncoming([SyncRemoteRecord(mutation: mutation, revision: 1, cursor: 1)])
        await #expect(throws: SyncError.revisionConflict) { try await store.synchronize(session: session) }
        #expect(try await store.allCredentials().first?.password == "local-secret")
        #expect(await fixture.mutations.count == 1)
        #expect(try await store.conflicts().count == 1)
        try await store.resolveConflict(id: credential.id, keepingLocal: false)
        #expect(try await store.allCredentials().first?.password == "remote-secret")
        #expect(await fixture.mutations.isEmpty)
    }

    @Test func offlineEditsCoalesceAndExplicitLocalResolutionRebases() async throws {
        let fixture = CloudCredentialFixtures()
        let store = await fixture.store()
        let credential = Credential(origin: Origin(scheme: "https", host: "example.com"),
                                    username: "person", password: "initial")
        try await store.save(credential)
        let edit = Credential(id: credential.id, origin: credential.origin,
                              username: credential.username, password: "latest")
        try await store.save(edit)
        #expect(await fixture.mutations.count == 1)
        #expect(try await store.allCredentials().first?.password == "latest")
        let session = try #require(await fixture.load())
        let incoming = Credential(id: credential.id, origin: credential.origin,
                                  username: "person", password: "remote")
        let request = SyncWriteRequest(identity: .init(accountID: session.accountID,
            collection: "credentials", recordID: incoming.id), expectedRevision: 0,
            plaintext: try JSONEncoder().encode(CloudCredentialPayload(incoming)))
        let mutation = try SyncMutationCipher().encrypt(request, rootKey: Data(repeating: 7, count: 32))
        await fixture.setIncoming([SyncRemoteRecord(mutation: mutation, revision: 1, cursor: 1)])
        await #expect(throws: SyncError.revisionConflict) { try await store.synchronize(session: session) }
        try await store.resolveConflict(id: credential.id, keepingLocal: true)
        #expect(await fixture.mutations.first?.expectedRevision == 1)
        #expect(try await store.conflicts().isEmpty)
        #expect(try await store.allCredentials().first?.password == "latest")
        #expect(try await store.synchronize(session: session).uploaded == 1)
    }
    @Test func importPullsCloudBeforeCheckingLoginConflict() async throws {
        let fixture = CloudCredentialFixtures()
        let store = await fixture.store()
        let session = try #require(await fixture.load())
        let remote = Credential(origin: Origin(scheme: "https", host: "example.com"),
                                username: "person", password: "remote-password")
        let request = SyncWriteRequest(identity: .init(accountID: session.accountID,
            collection: "credentials", recordID: remote.id), expectedRevision: 0,
            plaintext: try JSONEncoder().encode(CloudCredentialPayload(remote)))
        let mutation = try SyncMutationCipher().encrypt(request, rootKey: Data(repeating: 7, count: 32))
        await fixture.setIncoming([SyncRemoteRecord(mutation: mutation, revision: 1, cursor: 1)])
        let local = Credential(origin: remote.origin, username: remote.username, password: "local-password")
        await #expect(throws: PasswordStorageError.conflictingCredentials) {
            try await store.importCredentials([local])
        }
        #expect(await fixture.mutations.isEmpty)
        #expect(try await store.allCredentials().first?.password == "remote-password")
    }

}
