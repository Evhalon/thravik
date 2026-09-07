import Foundation
import RedentKit

/// Reads Chromium's `Login Data` SQLite database and decrypts each password.
enum LoginTableReader {
    struct LoginRead {
        var credentials: [Credential]
        var failedDecrypts: Int
    }

    private static let query = """
        SELECT origin_url, signon_realm, username_value, password_value FROM logins
        WHERE blacklisted_by_user = 0
        """

    static func read(from databaseURL: URL, key: [UInt8]) throws -> LoginRead {
        let db = try SQLiteDatabase(readOnlyAt: databaseURL)
        var credentials: [Credential] = []
        var failedDecrypts = 0

        try db.query(query) { row in
            guard let origin = origin(from: row.text(0), realm: row.text(1)) else { return }
            let username = (row.text(2) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard let encrypted = row.blob(3) else { return }
            guard let password = plaintextPassword(from: encrypted, key: key) else {
                failedDecrypts += 1
                return
            }
            guard !(username.isEmpty && password.isEmpty) else { return }
            credentials.append(Credential(origin: origin, username: username, password: password))
        }
        return LoginRead(credentials: credentials, failedDecrypts: failedDecrypts)
    }

    /// Chromium's `origin_url` is usually a full login URL. `signon_realm` is
    /// the fallback when that string is an android:// URI or otherwise unusable.
    static func origin(from originURL: String?, realm: String?) -> Origin? {
        parse(originURL) ?? parse(realm)
    }

    /// Decrypts one blob and strips the trailing 32-byte origin hash that
    /// newer Chromium builds append to the plaintext, if present. Rows that
    /// still don't decode as UTF-8 are skipped rather than failing the run.
    private static func plaintextPassword(from encrypted: Data, key: [UInt8]) -> String? {
        guard let plaintext = try? ChromiumCrypto.decrypt(encrypted, key: key) else { return nil }

        if plaintext.count > 32 {
            let leading = plaintext.prefix(plaintext.count - 32)
            let trailing = plaintext.suffix(32)
            if String(data: leading, encoding: .utf8) != nil, String(data: trailing, encoding: .utf8) == nil {
                return String(data: leading, encoding: .utf8)
            }
        }
        return String(data: plaintext, encoding: .utf8)
    }
}

private extension LoginTableReader {
    static func parse(_ raw: String?) -> Origin? {
        guard let raw, !raw.isEmpty else { return nil }
        if let url = URL(string: raw), let origin = Origin(url: url) { return origin }
        return looseOrigin(raw)
    }

    /// Foundation refuses some Chromium strings (unescaped characters in the
    /// path). The scheme+host prefix is still enough to match autofill.
    static func looseOrigin(_ raw: String) -> Origin? {
        guard let schemeRange = raw.range(of: "://") else { return nil }
        let scheme = String(raw[..<schemeRange.lowerBound]).lowercased()
        guard scheme == "http" || scheme == "https" else { return nil }
        let rest = raw[schemeRange.upperBound...]
        let hostPart = rest.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true).first
            .map(String.init) ?? String(rest)
        let host = hostPart.split(separator: ":").first.map(String.init) ?? hostPart
        guard !host.isEmpty else { return nil }
        return Origin(scheme: scheme, host: host)
    }
}
