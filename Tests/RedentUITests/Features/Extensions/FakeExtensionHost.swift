import Foundation
import RedentKit

@MainActor
final class FakeExtensionHost: ExtensionHosting {
    var installed: [InstalledExtension] = []
    var onChange: (@MainActor () -> Void)?
    var prepareFailure: ExtensionInstallError?
    private(set) var prepared: [ExtensionInstallSource] = []
    private(set) var discarded: [PendingExtension] = []

    static let manifest = ExtensionManifestSummary(
        name: "Blocker", version: "1.0", summary: "", permissions: ["Read and change all your data on all websites"]
    )

    func prepare(_ source: ExtensionInstallSource) async throws(ExtensionInstallError) -> PendingExtension {
        prepared.append(source)
        if let prepareFailure { throw prepareFailure }
        return PendingExtension(id: UUID(), manifest: Self.manifest, origin: .archive)
    }

    func commit(_ pending: PendingExtension) async throws(ExtensionInstallError) {
        installed.append(InstalledExtension(manifest: pending.manifest, origin: pending.origin))
        onChange?()
    }

    func discard(_ pending: PendingExtension) { discarded.append(pending) }

    func setEnabled(_ isEnabled: Bool, for id: UUID) {
        guard let index = installed.firstIndex(where: { $0.id == id }) else { return }
        installed[index].isEnabled = isEnabled
        onChange?()
    }

    func remove(_ id: UUID) {
        installed.removeAll { $0.id == id }
        onChange?()
    }

    func update(_ id: UUID) async throws(ExtensionInstallError) { throw .notUpdatable }
    func openOptions(for id: UUID) {}
    func hasOptionsPage(_ id: UUID) -> Bool { false }
    func iconPNG(for id: UUID) -> Data? { nil }
    func loadFailure(for id: UUID) -> String? { nil }
    func unsupportedFeatures(for id: UUID) -> [String] { [] }
}
