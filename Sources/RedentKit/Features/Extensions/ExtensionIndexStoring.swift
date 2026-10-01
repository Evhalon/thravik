import Foundation

/// Persists the list of installed extensions. The extensions' own files live
/// beside it on disk; this is only the record of which ones there are.
public protocol ExtensionIndexStoring: Sendable {
    func load() async -> [InstalledExtension]
    func save(_ extensions: [InstalledExtension]) async
}
