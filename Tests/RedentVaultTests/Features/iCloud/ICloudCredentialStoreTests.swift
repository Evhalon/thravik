import Foundation
import RedentKit
@testable import RedentVault
import Security
import Testing

@Suite struct ICloudCredentialStoreTests {
    @Test func queryRequiresDataProtectionAndSynchronizableItems() {
        let configuration = ICloudCredentialConfiguration(accessGroup: "TEAM.example.app")
        let query = SecurityICloudCredentialBackend.baseQuery(configuration)
        #expect(query[kSecAttrSynchronizable as String] as? Bool == true)
        #expect(query[kSecUseDataProtectionKeychain as String] as? Bool == true)
        #expect(query[kSecAttrAccessGroup as String] as? String == configuration.accessGroup)
    }

    @Test func unavailableSigningIdentityRejectsBeforeBackendWrites() async throws {
        let backend = MemoryCredentialBackend()
        let store = ICloudCredentialStore(configuration: .init(accessGroup: "TEAM.example.app"),
            backend: backend, teamIdentifier: nil)
        await #expect(throws: ICloudCredentialError.signingIdentityUnavailable) {
            try await store.save(credential())
        }
        #expect(await backend.count() == 0)
    }

    @Test func wrongAccessGroupIsRejectedBeforeWrites() async throws {
        let backend = MemoryCredentialBackend()
        let store = ICloudCredentialStore(configuration: .init(accessGroup: "OTHER.example.app"),
            backend: backend, teamIdentifier: "TEAM")
        await #expect(throws: ICloudCredentialError.invalidAccessGroup) {
            try await store.save(credential())
        }
        #expect(await backend.count() == 0)
    }

    @Test func saveReadOriginDeleteAndDuplicateImport() async throws {
        let backend = MemoryCredentialBackend()
        let store = ICloudCredentialStore(configuration: .init(accessGroup: "TEAM.example.app"),
            backend: backend, teamIdentifier: "TEAM")
        let first = credential()
        try await store.save(first)
        #expect(try await store.allCredentials() == [first])
        #expect(try await store.credentials(for: Origin(scheme: "https", host: "example.com")) == [first])
        #expect(try await store.importCredentials([first]).isEmpty)
        #expect(await backend.count() == 1)
        try await store.delete(first.id)
        #expect(try await store.allCredentials().isEmpty)
    }

    @Test func corruptMetadataFailsClosed() async throws {
        let backend = MemoryCredentialBackend()
        await backend.insert(.init(account: UUID().uuidString, password: Data("secret".utf8), metadata: Data([0])))
        let store = ICloudCredentialStore(configuration: .init(accessGroup: "TEAM.example.app"),
            backend: backend, teamIdentifier: "TEAM")
        await #expect(throws: ICloudCredentialError.invalidItem) {
            try await store.allCredentials()
        }
    }

    @Test func markUsedUpdatesMetadataOnly() async throws {
        let backend = MemoryCredentialBackend()
        let store = ICloudCredentialStore(configuration: .init(accessGroup: "TEAM.example.app"),
            backend: backend, teamIdentifier: "TEAM")
        let saved = credential()
        try await store.save(saved)
        try await store.markUsed(saved.id)
        let loaded = try await store.allCredentials()[0]
        #expect(loaded.password == saved.password)
        #expect(loaded.useCount == 1)
        #expect(loaded.lastUsedAt != nil)
    }

    private func credential() -> Credential {
        Credential(origin: Origin(scheme: "https", host: "example.com"),
                   username: "alex", password: "secret")
    }
}
