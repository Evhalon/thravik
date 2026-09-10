import Foundation
import Testing
@testable import RedentKit

@Suite("Site policy")
struct SitePolicyTests {
    private func origin(_ host: String) -> Origin { Origin(scheme: "https", host: host) }

    @Test("An undecided permission asks rather than allows")
    func defaultsToAsk() {
        let policy = SitePolicy(key: SiteKey(origin: origin("example.com"), containerID: BrowserContainer.defaultID))
        #expect(policy.decision(for: .camera) == .ask)
        #expect(policy.decision(for: .microphone) == .ask)
    }

    @Test("A permission granted to a subdomain does not reach the parent site")
    func exactHostScope() {
        let container = BrowserContainer.defaultID
        let sub = SiteKey(origin: origin("app.example.com"), containerID: container)
        let parent = SiteKey(origin: origin("example.com"), containerID: container)
        #expect(sub != parent)
    }

    @Test("The same site in two Containers holds two separate decisions")
    func containerScope() {
        let site = origin("example.com")
        #expect(SiteKey(origin: site, containerID: UUID()) != SiteKey(origin: site, containerID: UUID()))
    }

    @Test("http and https are different origins")
    func schemeScope() {
        let container = BrowserContainer.defaultID
        let secure = SiteKey(origin: Origin(scheme: "https", host: "example.com"), containerID: container)
        let plain = SiteKey(origin: Origin(scheme: "http", host: "example.com"), containerID: container)
        #expect(secure != plain)
    }

    @Test("A policy that decided nothing is not worth storing")
    func emptyPolicy() {
        var policy = SitePolicy(key: SiteKey(origin: origin("example.com"), containerID: BrowserContainer.defaultID))
        #expect(policy.isEmpty)
        policy.permissions[.camera] = .deny
        #expect(!policy.isEmpty)
    }

    @Test("A certificate exception is a durable site decision")
    func certificateExceptionIsNotEmpty() {
        var policy = SitePolicy(key: SiteKey(origin: origin("internal.example"), containerID: BrowserContainer.defaultID))
        policy.allowsInvalidCertificate = true
        #expect(!policy.isEmpty)
    }

    @Test("Policies written before certificate exceptions still decode")
    func decodesLegacyPolicy() throws {
        let encoded = """
        {"key":{"scheme":"https","host":"example.com","containerID":"\(UUID())"},"permissions":[]}
        """
        let policy = try JSONDecoder().decode(SitePolicy.self, from: Data(encoded.utf8))
        #expect(!policy.allowsInvalidCertificate)
    }

    @Test("A report with nothing found says so instead of claiming an erasure")
    func honestReport() {
        var report = ForgetSiteReport(domain: "example.com")
        #expect(report.removedNothing)
        #expect(report.retained.contains("Bookmarks"))
        report.clearedHistory = true
        #expect(!report.removedNothing)
    }
}
