import Foundation
import RedentKit

/// A provider switch never silently chooses between different passwords for one login.
enum PasswordStorageTransfer {
    static func copy(_ credentials: [Credential], to destination: any CredentialStoring) async throws {
        let existing = try await destination.allCredentials()
        let indexed = Dictionary(grouping: existing, by: identity)
        for credential in credentials {
            let matches = indexed[identity(credential)] ?? []
            guard matches.allSatisfy({ $0.password == credential.password })
            else { throw PasswordStorageError.conflictingCredentials }
        }
        _ = try await destination.importCredentials(credentials)
    }

    private static func identity(_ credential: Credential) -> String {
        "\(credential.origin.scheme)|\(credential.origin.host)|\(credential.username)"
    }
}
