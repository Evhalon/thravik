import Foundation
import RedentKit

/// The installed-extension list in one JSON file beside the extensions' own
/// folders. A missing or corrupt file reads as no extensions: the files stay
/// on disk and the user can add them again.
public struct JSONExtensionIndexStore: ExtensionIndexStoring {
    private let file: ExtensionIndexFile

    /// - Parameter fileURL: defaults to `~/Library/Application Support/Redent/extensions.json`.
    public init(fileURL: URL? = nil) {
        file = ExtensionIndexFile(fileURL: fileURL ?? RedentSupportDirectory.defaultFileURL(named: "extensions.json"))
    }

    public func load() async -> [InstalledExtension] { await file.load() }
    public func save(_ extensions: [InstalledExtension]) async { await file.save(extensions) }

    /// Where each extension's unpacked files live, one folder per install.
    public static func defaultFilesDirectory() -> URL {
        RedentSupportDirectory.defaultFileURL(named: "Extensions")
    }
}

/// An actor so two quick saves land on disk in the order they were made.
private actor ExtensionIndexFile {
    private let fileURL: URL

    init(fileURL: URL) { self.fileURL = fileURL }

    func load() -> [InstalledExtension] {
        (try? Data(contentsOf: fileURL))
            .flatMap { try? JSONDecoder().decode([InstalledExtension].self, from: $0) } ?? []
    }

    func save(_ extensions: [InstalledExtension]) {
        guard let data = try? JSONEncoder().encode(extensions) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: .atomic)
    }
}
