import Foundation

/// Where extensions live on disk: one folder per install, and a staging area
/// for packages the user has not yet confirmed.
struct ExtensionFiles: Sendable {
    let root: URL

    func installDirectory(_ id: UUID) -> URL {
        root.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    func stagingDirectory(_ id: UUID) -> URL {
        root.appendingPathComponent("Staging", isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
    }

    func deleteInstall(_ id: UUID) {
        try? FileManager.default.removeItem(at: installDirectory(id))
    }

    func deleteStaging(_ id: UUID) {
        try? FileManager.default.removeItem(at: stagingDirectory(id))
    }

    /// Moves a confirmed package into place, replacing an older copy.
    func promote(staged id: UUID, to installID: UUID) throws {
        let manager = FileManager.default
        let target = installDirectory(installID)
        try manager.createDirectory(at: root, withIntermediateDirectories: true)
        if manager.fileExists(atPath: target.path) { try manager.removeItem(at: target) }
        try manager.moveItem(at: stagingDirectory(id), to: target)
    }

    /// Store packages and zips sometimes wrap everything in one folder; the
    /// extension starts wherever `manifest.json` is.
    static func manifestRoot(in directory: URL) -> URL? {
        let manager = FileManager.default
        if manager.fileExists(atPath: directory.appendingPathComponent("manifest.json").path) {
            return directory
        }
        let children = (try? manager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles
        )) ?? []
        guard children.count == 1, let only = children.first else { return nil }
        return manager.fileExists(atPath: only.appendingPathComponent("manifest.json").path) ? only : nil
    }
}
