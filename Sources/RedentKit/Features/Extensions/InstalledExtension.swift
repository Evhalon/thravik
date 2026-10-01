import Foundation

/// One extension the user added, as the browser remembers it between launches.
///
/// Name, version and permissions are copied from the manifest at install time
/// so Settings can list an extension even when its files fail to load.
public struct InstalledExtension: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var name: String
    public var version: String
    public var summary: String
    public var origin: ExtensionOrigin
    public var permissions: [String]
    public var isEnabled: Bool
    public var installedAt: Date

    public init(
        id: UUID = UUID(),
        manifest: ExtensionManifestSummary,
        origin: ExtensionOrigin,
        isEnabled: Bool = true,
        installedAt: Date = .now
    ) {
        self.id = id
        self.name = manifest.name
        self.version = manifest.version
        self.summary = manifest.summary
        self.permissions = manifest.permissions
        self.origin = origin
        self.isEnabled = isEnabled
        self.installedAt = installedAt
    }

    /// Re-reads what the manifest says after an update replaced the files.
    public mutating func refresh(from manifest: ExtensionManifestSummary) {
        name = manifest.name
        version = manifest.version
        summary = manifest.summary
        permissions = manifest.permissions
    }
}

/// Where an extension came from, which decides whether it can be updated.
public enum ExtensionOrigin: Hashable, Sendable, Codable {
    case chromeWebStore(ChromeWebStoreID)
    case folder
    case archive

    public var label: String {
        switch self {
        case .chromeWebStore: "Chrome Web Store"
        case .folder: "Unpacked folder"
        case .archive: "Package file"
        }
    }
}

/// The few manifest facts the browser shows the user before and after install.
public struct ExtensionManifestSummary: Hashable, Sendable, Codable {
    public var name: String
    public var version: String
    public var summary: String
    /// Plain-language lines, such as "Read and change data on all websites".
    public var permissions: [String]
    /// Chrome-only features the extension asks for and WebKit does not have.
    public var unsupportedFeatures: [String]

    public init(
        name: String, version: String, summary: String, permissions: [String], unsupportedFeatures: [String] = []
    ) {
        self.name = name
        self.version = version
        self.summary = summary
        self.permissions = permissions
        self.unsupportedFeatures = unsupportedFeatures
    }
}
