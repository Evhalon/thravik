import Foundation

/// Resolves the on-disk location of Redent's local stores.
enum RedentSupportDirectory {
    /// `~/Library/Application Support/Redent/<fileName>`.
    static func defaultFileURL(named fileName: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Redent", isDirectory: true).appendingPathComponent(fileName)
    }
}
