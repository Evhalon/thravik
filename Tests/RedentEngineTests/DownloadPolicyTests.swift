import Testing
@testable import RedentEngine

/// Regression: a response the web view could render but the server sent as an
/// attachment was shown instead of saved, so the download never started.
@Suite("Download policy")
struct DownloadPolicyTests {
    @Test("A type the page cannot render is saved")
    func unrenderableIsSaved() {
        #expect(DownloadPolicy.shouldDownload(mimeType: "text/html", canShowMIMEType: false, contentDisposition: nil))
    }

    @Test("A renderable type is shown when nothing asks for a file")
    func renderableIsShown() {
        #expect(!DownloadPolicy.shouldDownload(mimeType: "text/html", canShowMIMEType: true, contentDisposition: nil))
        #expect(!DownloadPolicy.shouldDownload(mimeType: "text/html", canShowMIMEType: true, contentDisposition: "inline"))
    }

    @Test("An attachment is saved even when it could be rendered")
    func attachmentIsSaved() {
        #expect(DownloadPolicy.shouldDownload(
            mimeType: "application/pdf", canShowMIMEType: true,
            contentDisposition: "attachment; filename=\"report.pdf\""
        ))
    }

    /// Regression: a plain link to a `text/csv` file opened as a text page
    /// because WebKit can render any `text/*`; other browsers save it.
    @Test("A data file is saved even without an attachment disposition")
    func dataFileIsSaved() {
        #expect(DownloadPolicy.shouldDownload(
            mimeType: "text/csv", canShowMIMEType: true, contentDisposition: nil
        ))
        #expect(DownloadPolicy.isDataFile("Text/CSV"))
        #expect(DownloadPolicy.isDataFile("text/calendar"))
        #expect(!DownloadPolicy.isDataFile("text/plain"))
        #expect(!DownloadPolicy.isDataFile(nil))
    }

    @Test("The disposition type is matched case-insensitively and as a whole token")
    func dispositionParsing() {
        #expect(DownloadPolicy.isAttachment("Attachment"))
        #expect(DownloadPolicy.isAttachment("  ATTACHMENT ;filename=a.csv"))
        #expect(!DownloadPolicy.isAttachment("inline; filename=attachment.pdf"))
        #expect(!DownloadPolicy.isAttachment("attachments"))
    }
}
