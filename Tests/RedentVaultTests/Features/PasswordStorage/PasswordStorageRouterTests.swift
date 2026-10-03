import Foundation
import RedentKit
import RedentVault
import Testing

struct PasswordStorageRouterTests {
    @Test func writesUsageAndDeletionRemainInSelectedProvider() async throws {
        let local = RouterCredentialStore()
        let cloud = RouterCredentialStore()
        let apple = RouterCredentialStore()
        let router = PasswordStorageRouter(local: local, preferences: RouterPreferenceStore())
        await router.register(cloud, for: .redentCloud)
        await router.register(apple, for: .iCloud)
        let localCredential = credential("local")
        try await router.save(localCredential)
        try await router.select(.redentCloud, copyingCurrent: false)
        let cloudCredential = credential("cloud")
        try await router.save(cloudCredential)
        try await router.markUsed(cloudCredential.id)
        #expect(await cloud.allCredentials().first?.useCount == 1)
        #expect(try await router.allCredentials().map(\.id) == [cloudCredential.id])
        try await router.select(.iCloud, copyingCurrent: false)
        #expect(try await router.allCredentials().isEmpty)
        try await router.save(credential("apple"))
        try await router.select(.redentCloud, copyingCurrent: false)
        try await router.delete(cloudCredential.id)
        #expect(await cloud.allCredentials().isEmpty)
        #expect(await local.allCredentials().map(\.id) == [localCredential.id])
        #expect(await apple.allCredentials().count == 1)
    }

    @Test func conflictingMigrationPreservesBothProvidersAndSelection() async throws {
        let source = credential("same", password: "source")
        let target = credential("same", password: "target")
        let local = RouterCredentialStore([source])
        let cloud = RouterCredentialStore([target])
        let preferences = RouterPreferenceStore()
        let router = PasswordStorageRouter(local: local, preferences: preferences)
        await router.register(cloud, for: .redentCloud)
        await #expect(throws: PasswordStorageError.conflictingCredentials) {
            try await router.select(.redentCloud, copyingCurrent: true)
        }
        #expect(await router.selectedMode() == .local)
        #expect(await preferences.load() == .local)
        #expect(await local.allCredentials() == [source])
        #expect(await cloud.allCredentials() == [target])
    }

    @Test func failedImportKeepsOriginalProviderAndPreference() async throws {
        let source = credential("source")
        let local = RouterCredentialStore([source])
        let cloud = RouterCredentialStore()
        await cloud.failImports()
        let preferences = RouterPreferenceStore()
        let router = PasswordStorageRouter(local: local, preferences: preferences)
        await router.register(cloud, for: .redentCloud)
        await #expect(throws: VaultError.authenticationFailed) {
            try await router.select(.redentCloud, copyingCurrent: true)
        }
        #expect(await router.selectedMode() == .local)
        #expect(await preferences.load() == .local)
        #expect(try await router.allCredentials() == [source])
        #expect(await cloud.allCredentials().isEmpty)
    }

    @Test func preferenceFailureDoesNotActivateDestination() async throws {
        let preferences = RouterPreferenceStore()
        await preferences.failSaves()
        let router = PasswordStorageRouter(local: RouterCredentialStore(), preferences: preferences)
        await router.register(RouterCredentialStore(), for: .iCloud)
        await #expect(throws: PasswordStorageError.unavailable) {
            try await router.select(.iCloud, copyingCurrent: false)
        }
        #expect(await router.selectedMode() == .local)
        #expect(await preferences.load() == .local)
    }

    @Test func persistedCloudSelectionNeverFallsBackToLocal() async throws {
        let local = RouterCredentialStore([credential("private")])
        let router = PasswordStorageRouter(local: local, preferences: RouterPreferenceStore(.redentCloud))
        #expect(await router.selectedMode() == .redentCloud)
        await #expect(throws: PasswordStorageError.unavailable) { try await router.allCredentials() }
        await #expect(throws: PasswordStorageError.unavailable) { try await router.save(credential("new")) }
        #expect(await local.allCredentials().count == 1)
        let cloud = RouterCredentialStore()
        await router.register(cloud, for: .redentCloud)
        #expect(try await router.allCredentials().isEmpty)
        await router.unregister(.redentCloud)
        await #expect(throws: PasswordStorageError.unavailable) { try await router.allCredentials() }
        #expect(await router.selectedMode() == .redentCloud)
    }

    @Test func successfulMigrationCopiesWithoutDeletingSource() async throws {
        let source = credential("source")
        let local = RouterCredentialStore([source])
        let cloud = RouterCredentialStore()
        let preferences = RouterPreferenceStore()
        let router = PasswordStorageRouter(local: local, preferences: preferences)
        await router.register(cloud, for: .redentCloud)
        try await router.select(.redentCloud, copyingCurrent: true)
        #expect(await router.selectedMode() == .redentCloud)
        #expect(await preferences.load() == .redentCloud)
        #expect(await cloud.allCredentials() == [source])
        #expect(await local.allCredentials() == [source])
    }

    private func credential(_ username: String, password: String = "test-secret") -> Credential {
        Credential(origin: Origin(scheme: "https", host: "example.com"), username: username, password: password)
    }
}
