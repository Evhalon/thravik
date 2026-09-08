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

    /// The same login in two Spaces is two logins: a Space is a profile, and
    /// importing a work account must not be swallowed by the personal one.
    private static func key(_ credential: Credential) -> String {
        let space = credential.spaceID?.uuidString ?? "-"
        return "\(space)|\(credential.origin.scheme)|\(credential.origin.host)|\(credential.username)"
    }
}
