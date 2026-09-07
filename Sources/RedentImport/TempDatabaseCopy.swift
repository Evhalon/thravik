import Foundation
import RedentKit

/// Copies a SQLite database (and its `-wal`/`-shm` siblings, if present) to a
/// scratch directory so it can be read while the source browser still holds
/// an exclusive lock on the original.
struct TempDatabaseCopy {
    let databaseURL: URL
    private let directory: URL

    /// Copies `fileName` out of `profileURL` into a fresh temp directory.
    /// Throws `.databaseUnreadable` if the source file itself is missing.
    init(fileName: String, in profileURL: URL) throws {
        let source = profileURL.appending(path: fileName)
        guard FileManager.default.fileExists(atPath: source.path) else {
            throw ImportError.databaseUnreadable(fileName)
        }

        let scratch = FileManager.default.temporaryDirectory
            .appending(path: "redent-import-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        directory = scratch

        let destination = scratch.appending(path: fileName)
        try FileManager.default.copyItem(at: source, to: destination)
        databaseURL = destination

        for suffix in ["-wal", "-shm"] {
            let siblingSource = profileURL.appending(path: fileName + suffix)
            guard FileManager.default.fileExists(atPath: siblingSource.path) else { continue }
            let siblingDestination = scratch.appending(path: fileName + suffix)
            try? FileManager.default.copyItem(at: siblingSource, to: siblingDestination)
        }
    }

    /// Removes the whole scratch directory. Call on every exit path.
    func cleanUp() {
        try? FileManager.default.removeItem(at: directory)
    }
}
