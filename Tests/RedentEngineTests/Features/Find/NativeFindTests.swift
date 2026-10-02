import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Native document find", .serialized)
@MainActor
struct NativeFindTests {
    @Test("Native find reports a hit without fabricating the document's count")
    func reportsNativeResult() async throws {
        let tab = try await FindTestPage.saying("<p>Needle needle</p>")
        let view = try #require(tab.webView)

        #expect(await WebNativeFind.search("needle", forward: true, in: view) == .foundWithoutCount)
        #expect(await WebNativeFind.search("needle", forward: false, in: view) == .foundWithoutCount)
        #expect(await WebNativeFind.search("absent", forward: true, in: view) == .empty)
        #expect(await WebNativeFind.search("", forward: true, in: view) == .empty)
    }

    @Test("Native fallback reaches rendered text inside a closed shadow root")
    func findsClosedShadowText() async throws {
        let tab = try await FindTestPage.saying("""
        <x-card></x-card>
        <script>
        customElements.define('x-card', class extends HTMLElement {
          constructor() {
            super();
            this.attachShadow({ mode: 'closed' }).innerHTML = '<p>Native needle twice: needle</p>';
          }
        });
        </script>
        """)

        #expect(await tab.findInPage("needle", forward: true) == .foundWithoutCount)
        #expect(await tab.findInPage("needle", forward: false) == .foundWithoutCount)
    }

    @Test("Native search reaches text in a rendered PDF document")
    func findsPDFText() async throws {
        let tab = try await FindTestPage.saying("<p>placeholder</p>")
        let view = try #require(tab.webView)
        let baseURL = try #require(URL(string: "https://example.com/document.pdf"))
        view.load(pdfDocument(), mimeType: "application/pdf", characterEncodingName: "utf-8", baseURL: baseURL)
        try await waitForDocument(view)

        #expect(await tab.findInPage("needle", forward: true) == .foundWithoutCount)
        #expect(await tab.findInPage("needle", forward: false) == .foundWithoutCount)
        #expect(await tab.findInPage("absent", forward: true) == .empty)
    }

    private func waitForDocument(_ view: WKWebView) async throws {
        let deadline = ContinuousClock.now + .seconds(30)
        while view.isLoading, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(!view.isLoading)
        try await Task.sleep(for: .milliseconds(100))
    }

    private func pdfDocument() -> Data {
        let stream = "BT /F1 24 Tf 50 740 Td (native needle native needle) Tj ET"
        let objects = [
            "<< /Type /Catalog /Pages 2 0 R >>",
            "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
            "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
            "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
            "<< /Length \(stream.utf8.count) >>\nstream\n\(stream)\nendstream"
        ]
        var document = "%PDF-1.4\n"
        var offsets: [Int] = []
        for (index, object) in objects.enumerated() {
            offsets.append(document.utf8.count)
            document += "\(index + 1) 0 obj\n\(object)\nendobj\n"
        }
        let crossReference = document.utf8.count
        document += "xref\n0 \(objects.count + 1)\n0000000000 65535 f \n"
        for offset in offsets { document += String(format: "%010d 00000 n \n", offset) }
        document += "trailer\n<< /Size \(objects.count + 1) /Root 1 0 R >>\nstartxref\n\(crossReference)\n%%EOF\n"
        return Data(document.utf8)
    }
}
