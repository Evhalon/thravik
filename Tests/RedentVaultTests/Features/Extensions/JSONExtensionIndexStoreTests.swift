import Foundation
import RedentKit
import RedentVault
import Testing

struct JSONExtensionIndexStoreTests {
    private func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("extensions-\(UUID().uuidString).json")
    }

    @Test("Saved extensions read back exactly")
    func roundTrip() async throws {
        let url = temporaryFile()
        defer { try? FileManager.default.removeItem(at: url) }
        let id = try #require(ChromeWebStoreID("ddkjiahejlhfcafbddmgiahcphecmpfh"))
        let manifest = ExtensionManifestSummary(name: "Blocker", version: "1.2", summary: "", permissions: ["x"])
        let saved = [InstalledExtension(manifest: manifest, origin: .chromeWebStore(id), isEnabled: false)]
        await JSONExtensionIndexStore(fileURL: url).save(saved)
        #expect(await JSONExtensionIndexStore(fileURL: url).load() == saved)
    }

    @Test("A missing file reads as no extensions")
    func missingFile() async {
        #expect(await JSONExtensionIndexStore(fileURL: temporaryFile()).load().isEmpty)
    }
}
