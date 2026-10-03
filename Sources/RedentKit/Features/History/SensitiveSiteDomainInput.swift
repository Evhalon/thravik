import Foundation

public enum SensitiveSiteDomainInputError: Error, Equatable {
    case empty
    case invalidHost
}

/// Normalizes user-entered hosts and URLs to a registrable domain for storage.
public enum SensitiveSiteDomainInput {
    private static let hostCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789.-")

    public static func registrableDomain(from raw: String) -> Result<String, SensitiveSiteDomainInputError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return .failure(.empty) }
        guard let host = host(from: trimmed) else { return .failure(.invalidHost) }
        let domain = Origin(scheme: "https", host: host).registrableDomain
        guard domain.contains("."), !domain.hasPrefix("."), !domain.hasSuffix(".") else {
            return .failure(.invalidHost)
        }
        return .success(domain)
    }

    /// URL parsing drops a port, credentials, path and query the user pasted.
    static func host(from trimmed: String) -> String? {
        let address = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let components = URLComponents(string: address),
              let host = components.host?.lowercased(), !host.isEmpty,
              host.unicodeScalars.allSatisfy(hostCharacters.contains)
        else { return nil }
        return host.hasSuffix(".") ? String(host.dropLast()) : host
    }
}
