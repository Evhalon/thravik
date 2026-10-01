import Foundation
import RedentKit

/// Gets an extension's files into a staging folder, whatever it arrived as.
///
/// Everything here runs off the main actor: a store download, a zip
/// extraction and a folder copy are all slow enough to drop frames.
enum ExtensionUnpacker {
    static func unpack(
        _ source: ExtensionInstallSource, into destination: URL
    ) async throws(ExtensionInstallError) {
        let scratch = destination.deletingLastPathComponent()
            .appendingPathComponent(destination.lastPathComponent + "-raw", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: scratch) }
        switch source {
        case .chromeWebStore(let id):
            try await expand(package: try await download(id), into: scratch)
        case .archive(let file):
            guard let data = try? Data(contentsOf: file) else { throw .notAnExtensionPackage }
            try await expand(package: data, into: scratch)
        case .folder(let folder):
            try await copy(folder, to: scratch)
        }
        guard let root = ExtensionFiles.manifestRoot(in: scratch) else { throw .missingManifest }
        do {
            try FileManager.default.moveItem(at: root, to: destination)
        } catch {
            throw .unpackFailed
        }
    }

    private static func download(_ id: ChromeWebStoreID) async throws(ExtensionInstallError) -> Data {
        guard let url = id.downloadURL else { throw .downloadFailed }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200, !data.isEmpty else { throw ExtensionInstallError.downloadFailed }
            return data
        } catch {
            throw .downloadFailed
        }
    }

    private static func expand(package: Data, into folder: URL) async throws(ExtensionInstallError) {
        let zip: Data
        do {
            zip = try CRXArchive.zipPayload(of: package)
        } catch {
            throw .notAnExtensionPackage
        }
        let archive = folder.appendingPathExtension("zip")
        defer { try? FileManager.default.removeItem(at: archive) }
        do {
            try FileManager.default.createDirectory(
                at: archive.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try zip.write(to: archive)
        } catch {
            throw .unpackFailed
        }
        let listing = try await ArchiveTool.run("/usr/bin/zipinfo", ["-1", archive.path])
        // A path that climbs out of the folder would write anywhere on disk.
        let entries = listing.split(separator: "\n")
        guard !entries.contains(where: { $0.hasPrefix("/") || $0.contains("../") }) else { throw .unpackFailed }
        _ = try await ArchiveTool.run("/usr/bin/ditto", ["-x", "-k", archive.path, folder.path])
    }

    private static func copy(_ folder: URL, to scratch: URL) async throws(ExtensionInstallError) {
        let copied = await Task.detached {
            do {
                try FileManager.default.createDirectory(
                    at: scratch.deletingLastPathComponent(), withIntermediateDirectories: true
                )
                try FileManager.default.copyItem(at: folder, to: scratch)
                return true
            } catch {
                return false
            }
        }.value
        guard copied else { throw .unpackFailed }
    }
}
