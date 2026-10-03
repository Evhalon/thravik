import Foundation

public enum ManagedURLBlocklist {
    /// A pattern names a host or a registrable domain. A registrable domain
    /// covers its subdomains; a deeper host covers only itself. Never substring.
    public static func isBlocked(url: URL, patterns: [String]) -> Bool {
        guard !patterns.isEmpty, let origin = Origin(url: url) else { return false }
        let host = origin.host
        let domain = origin.registrableDomain
        return patterns.contains { raw in
            guard let pattern = normalizedHost(raw) else { return false }
            return pattern == host || pattern == domain
        }
    }

    /// Kept as a host, not reduced to eTLD+1: `mail.example.com` must not
    /// block all of `example.com`.
    private static func normalizedHost(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }
        return SensitiveSiteDomainInput.host(from: trimmed) ?? trimmed
    }
}
