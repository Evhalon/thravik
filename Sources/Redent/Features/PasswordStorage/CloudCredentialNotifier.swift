import Foundation
import RedentKit

struct CloudCredentialNotifier: CredentialStoring {
    let underlying: any CredentialStoring
    let prepareAccess: @Sendable () async -> Void
    let changed: @Sendable () -> Void

    func credentials(for origin: Origin) async throws -> [Credential] {
        await prepareAccess()
        let credentials = try await underlying.credentials(for: origin)
        changed()
        return credentials
    }
    func allCredentials() async throws -> [Credential] {
        await prepareAccess()
        let credentials = try await underlying.allCredentials()
        changed()
        return credentials
    }
    func save(_ credential: Credential) async throws {
        await prepareAccess()
        try await underlying.save(credential)
        changed()
    }
    func importCredentials(_ credentials: [Credential]) async throws -> [Credential] {
        await prepareAccess()
        let added = try await underlying.importCredentials(credentials)
        if !added.isEmpty { changed() }
        return added
    }
    func markUsed(_ id: UUID) async throws {
        await prepareAccess()
        try await underlying.markUsed(id)
        changed()
    }
    func delete(_ id: UUID) async throws {
        await prepareAccess()
        try await underlying.delete(id)
        changed()
    }
}
