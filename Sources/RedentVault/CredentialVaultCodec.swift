import Foundation
import RedentKit

enum CredentialVaultCodec {
    private struct Entry: Codable {
        let id: UUID
        let scheme: String
        let host: String
        let username: String
        let password: String
        let createdAt: Date
        var lastUsedAt: Date?
        var useCount: Int

        init(_ credential: Credential) {
            id = credential.id
            scheme = credential.origin.scheme
            host = credential.origin.host
            username = credential.username
            password = credential.password
            createdAt = credential.createdAt
            lastUsedAt = credential.lastUsedAt
            useCount = credential.useCount
        }

        var credential: Credential {
            Credential(
                id: id,
                origin: Origin(scheme: scheme, host: host),
                username: username,
                password: password,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
                useCount: useCount
            )
        }
    }

    static func encode(_ credentials: [Credential]) throws -> Data {
        try JSONEncoder().encode(credentials.map(Entry.init))
    }

    static func decode(_ data: Data) throws -> [Credential] {
        do {
            return try JSONDecoder().decode([Entry].self, from: data).map(\.credential)
        } catch {
            throw VaultError.invalidData
        }
    }
}
