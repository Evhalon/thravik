import Foundation

/// Decides whether a response is saved to disk rather than shown.
///
/// Pure so the rule is testable without a live `WKNavigationResponse`.
enum DownloadPolicy {
    /// A server that sends `Content-Disposition: attachment` has asked for a
    /// file, even for a type the web view could render — a PDF export, a CSV,
    /// an image behind a "Download" button. Showing it instead is the bug
    /// people describe as "the download never started".
    static func shouldDownload(
        mimeType: String?,
        canShowMIMEType: Bool,
        contentDisposition: String?
    ) -> Bool {
        !canShowMIMEType || isDataFile(mimeType) || isAttachment(contentDisposition)
    }

    /// WebKit renders any `text/*` as plain text, but a CSV, calendar or
    /// contact card is a file for another app, not a page to read. Other
    /// browsers save these, so a plain link to `import_example.csv` must too.
    static func isDataFile(_ mimeType: String?) -> Bool {
        guard let mimeType else { return false }
        return dataFileTypes.contains(mimeType.lowercased())
    }

    private static let dataFileTypes: Set<String> = [
        "text/csv", "text/x-csv", "application/csv", "text/comma-separated-values",
        "text/tab-separated-values", "text/calendar",
        "text/vcard", "text/x-vcard", "text/directory",
    ]

    /// The disposition type is the token before the first `;`, compared
    /// case-insensitively (RFC 6266 §4.2).
    static func isAttachment(_ contentDisposition: String?) -> Bool {
        guard let contentDisposition else { return false }
        let type = contentDisposition.split(separator: ";", maxSplits: 1).first ?? ""
        return type.trimmingCharacters(in: .whitespaces).lowercased() == "attachment"
    }
}
