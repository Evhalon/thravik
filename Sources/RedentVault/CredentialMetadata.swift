import Foundation
import RedentKit

/// JSON payload stored in `kSecAttrGeneric` for a credential item. The
/// password lives only in `kSecValueData`, so listing origins never needs to
/// decrypt it.
struct CredentialMetadata: Codable {
    let scheme: String
    let host: String
    let username: String
    let createdAt: Date
    var lastUsedAt: Date?
    var useCount: Int

    init(credential: Credential) {
        scheme = credential.origin.scheme
        host = credential.origin.host
        username = credential.username
        createdAt = credential.createdAt
        lastUsedAt = credential.lastUsedAt
        useCount = credential.useCount
    }

    func credential(id: UUID, password: String) -> Credential {
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
