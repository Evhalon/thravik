import Foundation

/// Drops logins we already hold, including duplicates inside the import itself.
public enum CredentialImportDeduper {
    public static func newcomers(in found: [Credential], alreadyHave existing: [Credential]) -> [Credential] {
        var seen = Set(existing.map(key))
        var fresh: [Credential] = []
        for credential in found {
            let identity = key(credential)
            guard !seen.contains(identity) else { continue }
            seen.insert(identity)
            fresh.append(credential)
        }
        return fresh
    }

    private static func key(_ credential: Credential) -> String {
        "\(credential.origin.scheme)|\(credential.origin.host)|\(credential.username)"
    }
}
