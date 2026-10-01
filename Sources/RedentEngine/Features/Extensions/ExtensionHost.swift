import AppKit
import Observation
import RedentKit
import WebKit

/// Runs the user's WebExtensions — the Chrome extension format — through
/// WebKit's own extension support, one `WKWebExtensionController` for the app.
///
/// Every regular window's tabs are attached to that controller, so an
/// extension sees the same tab list the user does. Private windows are never
/// attached, matching Chrome's default of keeping extensions out of
/// incognito. A hibernated tab stays visible to extensions through its
/// snapshot; it simply has no page for them to script until it wakes.
@MainActor
@Observable
public final class ExtensionHost: ExtensionHosting {
    public internal(set) var installed: [InstalledExtension] = []
    @ObservationIgnored public var onChange: (@MainActor () -> Void)?
    /// Bumped whenever an extension changes its toolbar icon, badge or title,
    /// so the toolbar redraws without polling.
    private(set) var actionRevision = 0

    @ObservationIgnored let controller: WKWebExtensionController
    @ObservationIgnored let files: ExtensionFiles
    @ObservationIgnored let index: any ExtensionIndexStoring
    @ObservationIgnored var contexts: [UUID: WKWebExtensionContext] = [:]
    @ObservationIgnored var failures: [UUID: String] = [:]
    @ObservationIgnored var staged: [UUID: PendingExtension] = [:]
    @ObservationIgnored var windows: [ExtensionWindow] = []
    /// The toolbar button last pressed: where an action's popup points from.
    @ObservationIgnored weak var popupAnchor: NSView?
    @ObservationIgnored private var delegate: ExtensionControllerDelegate?

    /// Fixed so `chrome.storage` and granted permissions survive relaunch.
    private static let storageID = UUID(uuid: (
        0x52, 0x45, 0x44, 0x45, 0x4E, 0x54, 0x45, 0x58, 0x54, 0x45, 0x4E, 0x53, 0x49, 0x4F, 0x4E, 0x53
    ))

    public init(filesDirectory: URL, index: any ExtensionIndexStoring) {
        self.files = ExtensionFiles(root: filesDirectory)
        self.index = index
        self.controller = WKWebExtensionController(
            configuration: WKWebExtensionController.Configuration(identifier: Self.storageID)
        )
        let delegate = ExtensionControllerDelegate(host: self)
        self.delegate = delegate
        controller.delegate = delegate
    }

    /// Reads the saved list and starts every enabled extension.
    public func start() async {
        installed = await index.load()
        for record in installed where record.isEnabled {
            await load(record)
        }
        changed()
    }

    public func setEnabled(_ isEnabled: Bool, for id: UUID) {
        guard let position = installed.firstIndex(where: { $0.id == id }),
              installed[position].isEnabled != isEnabled else { return }
        installed[position].isEnabled = isEnabled
        let record = installed[position]
        if isEnabled {
            Task { await load(record); changed() }
        } else {
            unload(id)
        }
        persist()
    }

    public func remove(_ id: UUID) {
        unload(id)
        installed.removeAll { $0.id == id }
        failures[id] = nil
        files.deleteInstall(id)
        persist()
    }

    public func hasOptionsPage(_ id: UUID) -> Bool {
        contexts[id]?.webExtension.hasOptionsPage ?? false
    }

    public func loadFailure(for id: UUID) -> String? { failures[id] }

    public func unsupportedFeatures(for id: UUID) -> [String] {
        guard let webExtension = contexts[id]?.webExtension else { return [] }
        return ExtensionPermissionWording.featureNames(Self.droppedPermissions(of: webExtension))
    }

    public func iconPNG(for id: UUID) -> Data? {
        guard let image = contexts[id]?.webExtension.icon(for: CGSize(width: 32, height: 32)),
              let tiff = image.tiffRepresentation else { return nil }
        return NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
    }

    func changed() {
        actionRevision += 1
        onChange?()
    }

    func persist() {
        let snapshot = installed
        Task { await index.save(snapshot) }
        changed()
    }
}
