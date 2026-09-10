import Foundation
import RedentKit
import Testing
@testable import RedentEngine

@Suite("Page trust issues")
struct PageTrustIssueResolverTests {
    @Test("Certificate failures present a trust warning")
    func identifiesCertificateFailures() {
        let certificateCodes: [URLError.Code] = [
            .serverCertificateHasBadDate,
            .serverCertificateUntrusted,
            .serverCertificateHasUnknownRoot,
            .serverCertificateNotYetValid
        ]

        for code in certificateCodes {
            let error = NSError(domain: NSURLErrorDomain, code: code.rawValue)
            #expect(PageTrustIssueResolver.resolve(error) == .invalidCertificate)
        }
    }

    @Test("Other transport failures do not claim a certificate issue")
    func ignoresNonCertificateFailures() {
        let error = NSError(domain: NSURLErrorDomain, code: URLError.Code.notConnectedToInternet.rawValue)
        #expect(PageTrustIssueResolver.resolve(error) == nil)
    }

    @Test("A certificate failure preserves the requested address")
    @MainActor
    func certificateFailureKeepsTabOpen() throws {
        let controller = TabController(
            session: BrowserSession(), settings: BrowserSettings(), logger: TrustIssueLogger()
        )
        let url = try #require(URL(string: "https://internal.example"))
        let tab = try #require(controller.newTab(url: nil) as? WebTab)
        tab.beginNavigation(to: url)
        let error = NSError(domain: NSURLErrorDomain, code: URLError.Code.serverCertificateUntrusted.rawValue)

        tab.handleProvisionalFailure(error)

        #expect(tab.url == url)
        #expect(tab.snapshot.url == url)
        #expect(tab.pageTrustIssue == .invalidCertificate)
    }

    @Test("Proceeding records an exception for the exact host")
    @MainActor
    func proceedingRecordsTrustedHost() throws {
        let controller = TabController(
            session: BrowserSession(), settings: BrowserSettings(), logger: TrustIssueLogger()
        )
        let url = try #require(URL(string: "https://internal.example"))
        let tab = try #require(controller.newTab(url: nil) as? WebTab)
        var recordedKey: SiteKey?
        controller.trustInvalidCertificate = { recordedKey = $0 }
        tab.beginNavigation(to: url)
        tab.handleProvisionalFailure(NSError(
            domain: NSURLErrorDomain, code: URLError.Code.serverCertificateUntrusted.rawValue
        ))

        tab.proceedThroughInvalidCertificate()

        let expected = SiteKey(
            origin: Origin(scheme: "https", host: "internal.example"),
            containerID: tab.snapshot.containerID ?? BrowserContainer.defaultID
        )
        #expect(recordedKey == expected)
        #expect(tab.pageTrustIssue == nil)
    }
}

private struct TrustIssueLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
