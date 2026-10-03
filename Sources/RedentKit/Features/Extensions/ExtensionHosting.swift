import Foundation

/// What a user can ask of the browser's extension support.
///
/// Installing is two steps on purpose: `prepare` unpacks and reads the
/// extension without running any of it, so the user sees what it may access
/// before `commit` lets it into a page.
@MainActor
public protocol ExtensionHosting: AnyObject {
    var installed: [InstalledExtension] { get }
    /// Fires after any change to `installed`.
    var onChange: (@MainActor () -> Void)? { get set }

    func prepare(_ source: ExtensionInstallSource) async throws(ExtensionInstallError) -> PendingExtension
    func commit(_ pending: PendingExtension) async throws(ExtensionInstallError)
    func discard(_ pending: PendingExtension)

    func setEnabled(_ isEnabled: Bool, for id: UUID)
    func remove(_ id: UUID)
    /// Downloads the store's current package and replaces the files in place.
    func update(_ id: UUID) async throws(ExtensionInstallError)
    func openOptions(for id: UUID)
    func hasOptionsPage(_ id: UUID) -> Bool
    /// PNG data for the extension's own icon, when it loaded and has one.
    func iconPNG(for id: UUID) -> Data?
    /// The reason an installed extension did not load, if it did not.
    func loadFailure(for id: UUID) -> String?
    /// Chrome-only features a loaded extension asked for that WebKit lacks.
    func unsupportedFeatures(for id: UUID) -> [String]
}

public enum ExtensionInstallSource: Sendable, Equatable {
    case chromeWebStore(ChromeWebStoreID)
    /// A folder holding `manifest.json`: an extension in development.
    case folder(URL)
    /// A `.crx` or `.zip` file on disk.
    case archive(URL)
}

/// An extension unpacked into staging and read, but not yet running.
public struct PendingExtension: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let manifest: ExtensionManifestSummary
    public let origin: ExtensionOrigin
    /// Set when the package replaces one already installed.
    public let replacing: UUID?

    public init(id: UUID, manifest: ExtensionManifestSummary, origin: ExtensionOrigin, replacing: UUID? = nil) {
        self.id = id
        self.manifest = manifest
        self.origin = origin
        self.replacing = replacing
    }
}

public enum ExtensionInstallError: Error, Equatable, Sendable {
    case downloadFailed
    case notAnExtensionPackage
    case unpackFailed
    case missingManifest
    case invalidManifest(String)
    case alreadyInstalled(String)
    case notUpdatable
    case loadFailed(String)
    case blockedByOrganization

    public var message: String {
        switch self {
        case .blockedByOrganization: "Your organization does not allow installing this extension."
        case .downloadFailed: "The Chrome Web Store did not send the extension. Check the link and your connection."
        case .notAnExtensionPackage: "That file is not a Chrome extension package (.crx or .zip)."
        case .unpackFailed: "The extension package could not be unpacked."
        case .missingManifest: "No manifest.json was found. Choose the folder that contains it."
        case .invalidManifest(let reason): "The extension's manifest could not be read: \(reason)"
        case .alreadyInstalled(let name): "\(name) is already installed."
        case .notUpdatable: "Only extensions from the Chrome Web Store can be updated here."
        case .loadFailed(let reason): "The extension could not start: \(reason)"
        }
    }
}
