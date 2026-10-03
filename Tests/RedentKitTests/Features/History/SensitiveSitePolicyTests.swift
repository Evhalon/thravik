import Foundation
import Testing
@testable import RedentKit

@Suite("Sensitive site history policy")
struct SensitiveSitePolicyTests {
    private func url(_ raw: String) throws -> URL {
        try #require(URL(string: raw))
    }

    @Test("Custom list matches subdomains via registrable domain")
    func customDomainMatchesSubdomain() throws {
        let policy = SensitiveSitePolicy(customDomains: ["chase.com"])
        #expect(policy.excludes(url: try url("https://online.chase.com/login")))
        #expect(!policy.excludes(url: try url("https://chase.org/login")))
    }

    @Test("Built-in toggle uses the conservative list")
    func builtInToggle() throws {
        let policy = SensitiveSitePolicy(excludeBankingAndHealth: true)
        #expect(policy.excludes(url: try url("https://www.paypal.com/signin")))
        #expect(!policy.excludes(url: try url("https://example.com/")))
    }

    @Test("Multi-label suffixes resolve before matching")
    func coUkSuffix() throws {
        let policy = SensitiveSitePolicy(customDomains: ["example.co.uk"])
        #expect(policy.excludes(url: try url("https://shop.example.co.uk/cart")))
        #expect(!policy.excludes(url: try url("https://example.com/")))
    }

    @Test("IP literals match the address itself")
    func ipLiteral() throws {
        let policy = SensitiveSitePolicy(customDomains: ["192.168.1.10"])
        #expect(policy.excludes(url: try url("https://192.168.1.10/")))
        #expect(!policy.excludes(url: try url("https://192.168.1.11/")))
    }

    @Test("Domain input rejects invalid hosts")
    func invalidInput() {
        #expect(SensitiveSiteDomainInput.registrableDomain(from: "") == .failure(.empty))
        #expect(SensitiveSiteDomainInput.registrableDomain(from: "not a host") == .failure(.invalidHost))
    }

    @Test("Domain input normalizes pasted URLs and www")
    func normalizesInput() {
        #expect(SensitiveSiteDomainInput.registrableDomain(from: "https://www.bank.com/path") == .success("bank.com"))
    }

    @Test("Domain input drops ports, credentials, case and a trailing dot")
    func normalizesHostForms() {
        #expect(SensitiveSiteDomainInput.registrableDomain(from: "Online.CHASE.com:8443/x?y=1") == .success("chase.com"))
        #expect(SensitiveSiteDomainInput.registrableDomain(from: "user@secure.chase.com") == .success("chase.com"))
        #expect(SensitiveSiteDomainInput.registrableDomain(from: "chase.com.") == .success("chase.com"))
        #expect(SensitiveSiteDomainInput.registrableDomain(from: "192.168.1.10") == .success("192.168.1.10"))
        #expect(SensitiveSiteDomainInput.registrableDomain(from: "localhost") == .failure(.invalidHost))
        #expect(SensitiveSiteDomainInput.registrableDomain(from: "chase$.com") == .failure(.invalidHost))
    }

    @Test("URL forms with uppercase and a trailing dot still match")
    func matchesHostVariants() throws {
        let policy = SensitiveSitePolicy(customDomains: ["chase.com"])
        #expect(policy.excludes(url: try url("https://WWW.Chase.COM/")))
        #expect(policy.excludes(url: try url("https://secure.chase.com./")))
        #expect(!policy.excludes(url: try url("https://evilchase.com/")))
        #expect(!policy.excludes(url: try url("https://chase.com.evil.net/")))
    }

    @Test("Stored hosts reduce to their registrable domain")
    func normalizesStoredDomains() throws {
        var settings = BrowserSettings()
        settings.sensitiveSiteHistoryDomains = ["Secure.Chase.com"]
        #expect(SensitiveSitePolicy(settings: settings).excludes(url: try url("https://chase.com/")))
    }

    @Test("Adding a domain twice keeps one entry")
    func addDeduplicates() {
        var settings = BrowserSettings()
        _ = settings.addSensitiveHistoryDomain("chase.com")
        _ = settings.addSensitiveHistoryDomain("https://www.chase.com/login")
        #expect(settings.sensitiveSiteHistoryDomains == ["chase.com"])
    }

    @Test("Legacy settings JSON keeps history behavior")
    func legacySettingsDecode() throws {
        let legacy = Data(#"{"tabLayout":"sidebar","blocksTrackers":true}"#.utf8)
        let settings = try JSONDecoder().decode(BrowserSettings.self, from: legacy)
        #expect(!settings.excludeBankingAndHealthFromHistory)
        #expect(settings.sensitiveSiteHistoryDomains.isEmpty)
    }
}
