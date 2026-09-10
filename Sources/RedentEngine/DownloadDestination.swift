import Foundation

/// Where a download is fetched to, and where it ends up.
///
/// The two are not the same place. WebKit writes the bytes from its own
/// sandboxed network process, and that process cannot write into the user's
/// Downloads folder: macOS refuses it with no error at all, leaving a download
/// that never progresses and never fails. So the fetch lands in a private
/// staging folder, and this app — which does have access — moves the finished
/// file across itself.
enum DownloadDestination {
    static var downloadsDirectory: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
    }

    /// A folder of its own per download, so two fetches of the same name
    /// cannot collide before either has finished.
    static func stagingURL(for suggestedFilename: String) throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("app.redent.browser/downloads/\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(sanitize(suggestedFilename))
    }

    /// Moves a finished fetch into Downloads under a free name.
    /// - Returns: where it now is.
    static func moveToDownloads(_ staged: URL) throws -> URL {
        let target = uniqueURL(for: staged.lastPathComponent, in: downloadsDirectory)
        try FileManager.default.moveItem(at: staged, to: target)
        discardStaging(staged)
        return target
    }

    /// Drops the private folder a download was fetched into, finished or not.
    static func discardStaging(_ staged: URL) {
        try? FileManager.default.removeItem(at: staged.deletingLastPathComponent())
    }

    /// `report.pdf` → `report.pdf`, or `report 2.pdf` when the first is taken.
    ///
    /// - Parameter exists: injected so the rule is testable; defaults to disk.
    static func uniqueURL(
        for suggestedFilename: String,
        in directory: URL,
        exists: (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }
    ) -> URL {
        let name = sanitize(suggestedFilename)
        let candidate = directory.appendingPathComponent(name)
        guard exists(candidate) else { return candidate }
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        // Bounded: a directory with two thousand copies of one name is a
        // pathological case, and an unbounded loop here would hang the fetch.
        for index in 2...2000 {
            let numbered = ext.isEmpty ? "\(base) \(index)" : "\(base) \(index).\(ext)"
            let next = directory.appendingPathComponent(numbered)
            if !exists(next) { return next }
        }
        return directory.appendingPathComponent("\(base) \(UUID().uuidString)")
    }

    /// A server-supplied name is untrusted input. Only the last path component
    /// survives, so a name carrying `../` cannot place the file anywhere but
    /// the downloads folder, and a leading dot cannot hide it there.
    static func sanitize(_ suggested: String) -> String {
        let component = suggested.split(separator: "/").last.map(String.init) ?? ""
        let cleaned = component
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let visible = cleaned.drop { $0 == "." }
        return visible.isEmpty ? "download" : String(visible)
    }
}
