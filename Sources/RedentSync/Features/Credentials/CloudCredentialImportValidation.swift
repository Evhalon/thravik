import RedentKit

struct CloudCredentialImportValidation {
    static func validate(_ incoming: [Credential], existing: [Credential]) throws {
        let indexed = Dictionary(grouping: existing, by: identity)
        for credential in incoming {
            guard (indexed[identity(credential)] ?? []).allSatisfy({ $0.password == credential.password })
            else { throw PasswordStorageError.conflictingCredentials }
        }
    }

    private static func identity(_ credential: Credential) -> String {
        "\(credential.origin.scheme)|\(credential.origin.host)|\(credential.username)"
    }
}
