import Foundation
import RedentKit
import Testing
@testable import RedentEngine

@Suite("Extension host")
@MainActor
struct ExtensionHostTests {
    private actor MemoryIndex: ExtensionIndexStoring {
        private(set) var saved: [InstalledExtension] = []
        func load() -> [InstalledExtension] { saved }
        func save(_ extensions: [InstalledExtension]) { saved = extensions }
    }

    private func fixture() throws -> URL {
        let resources = try #require(Bundle.module.resourceURL)
        return resources.appendingPathComponent("Fixtures/SampleExtension", isDirectory: true)
    }

    private func scratch() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("redent-ext-\(UUID().uuidString)")
    }

    @Test("A folder is reviewed, installed, loaded, and removed")
    func folderLifecycle() async throws {
        let root = scratch()
        defer { try? FileManager.default.removeItem(at: root) }
        let host = ExtensionHost(filesDirectory: root, index: MemoryIndex())

        let pending = try await host.prepare(.folder(try fixture()))
        #expect(pending.manifest.name == "Sample Highlighter")
        #expect(pending.manifest.version == "1.4.0")
        #expect(pending.manifest.permissions.contains("Read and change your data on example.com"))
        #expect(host.installed.isEmpty)
        #expect(pending.manifest.unsupportedFeatures == ["Offscreen documents", "Tab audio and video capture"])

        try await host.commit(pending)
        let installed = try #require(host.installed.first)
        #expect(host.loadFailure(for: installed.id) == nil)
        #expect(host.contexts[installed.id] != nil)
        #expect(host.unsupportedFeatures(for: installed.id).count == 2)

        host.remove(installed.id)
        #expect(host.installed.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent(installed.id.uuidString).path))
    }

    @Test("A zip package installs the same as its folder")
    func zipPackage() async throws {
        let root = scratch()
        let archive = scratch().appendingPathExtension("zip")
        defer {
            try? FileManager.default.removeItem(at: root)
            try? FileManager.default.removeItem(at: archive)
        }
        _ = try await ArchiveTool.run("/usr/bin/ditto", ["-c", "-k", "--keepParent", try fixture().path, archive.path])
        let host = ExtensionHost(filesDirectory: root, index: MemoryIndex())
        let pending = try await host.prepare(.archive(archive))
        #expect(pending.manifest.name == "Sample Highlighter")
        host.discard(pending)
        #expect(!FileManager.default.fileExists(atPath: host.files.stagingDirectory(pending.id).path))
    }

    @Test("A folder without a manifest is refused")
    func missingManifest() async throws {
        let empty = scratch()
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: empty) }
        let host = ExtensionHost(filesDirectory: scratch(), index: MemoryIndex())
        await #expect(throws: ExtensionInstallError.missingManifest) {
            _ = try await host.prepare(.folder(empty))
        }
    }

    @Test("The same store extension cannot be added twice")
    func duplicateStoreInstall() async throws {
        let id = try #require(ChromeWebStoreID("ddkjiahejlhfcafbddmgiahcphecmpfh"))
        let index = MemoryIndex()
        let manifest = ExtensionManifestSummary(name: "uBlock", version: "1", summary: "", permissions: [])
        await index.save([InstalledExtension(manifest: manifest, origin: .chromeWebStore(id), isEnabled: false)])
        let host = ExtensionHost(filesDirectory: scratch(), index: index)
        await host.start()
        await #expect(throws: ExtensionInstallError.alreadyInstalled("uBlock")) {
            _ = try await host.prepare(.chromeWebStore(id))
        }
    }
}
