import Foundation

/// Registrable-domain resolution against a compact public-suffix list.
///
/// The full IANA list is ~10k entries; carrying it would bloat the binary for
/// no practical gain. These cover the multi-label suffixes real users meet.
enum PublicSuffix {
    private static let multiLabel: Set<String> = [
        "co.uk", "org.uk", "me.uk", "gov.uk", "ac.uk", "net.uk", "sch.uk",
        "com.au", "net.au", "org.au", "edu.au", "gov.au", "id.au",
        "co.nz", "net.nz", "org.nz", "govt.nz", "ac.nz",
        "co.jp", "or.jp", "ne.jp", "ac.jp", "go.jp", "lg.jp",
        "com.br", "net.br", "org.br", "gov.br", "edu.br",
        "com.cn", "net.cn", "org.cn", "gov.cn", "edu.cn", "ac.cn",
        "co.in", "net.in", "org.in", "gov.in", "ac.in", "edu.in",
        "com.mx", "org.mx", "gob.mx", "com.ar", "gob.ar", "com.co",
        "co.za", "org.za", "co.kr", "or.kr", "go.kr", "ne.kr",
        "com.tr", "gov.tr", "edu.tr", "com.tw", "org.tw", "gov.tw",
        "com.hk", "org.hk", "gov.hk", "com.sg", "com.my", "com.ph",
        "co.id", "or.id", "co.il", "org.il", "gov.il", "ac.il",
        "com.es", "gob.es", "com.pt", "gov.pt", "com.pl", "gov.pl",
        "com.ru", "org.ru", "net.ru", "com.ua", "gov.ua",
        "com.gr", "gov.gr", "com.vn", "gov.vn", "com.sa", "com.eg",
        "github.io", "gitlab.io", "pages.dev", "workers.dev", "vercel.app",
        "netlify.app", "herokuapp.com", "web.app", "firebaseapp.com",
        "s3.amazonaws.com", "cloudfront.net", "azurewebsites.net"
    ]

    /// `mail.google.com` → `google.com`; `shop.foo.co.uk` → `foo.co.uk`.
    /// Returns `nil` for IP literals, `localhost`, and single-label hosts.
    static func registrableDomain(of host: String) -> String? {
        guard !host.isEmpty, !isIPLiteral(host) else { return nil }
        let labels = host.split(separator: ".").map(String.init)
        guard labels.count >= 2 else { return nil }

        if labels.count >= 3 {
            let lastTwo = labels.suffix(2).joined(separator: ".")
            if multiLabel.contains(lastTwo) {
                return labels.suffix(3).joined(separator: ".")
            }
        }
        return labels.suffix(2).joined(separator: ".")
    }

    private static func isIPLiteral(_ host: String) -> Bool {
        if host.contains(":") { return true }
        let parts = host.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { UInt8($0) != nil }
    }
}
