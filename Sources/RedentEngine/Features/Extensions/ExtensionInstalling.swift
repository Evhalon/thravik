import Foundation
import RedentKit
import WebKit

/// Install, update and the confirmation step between them.
extension ExtensionHost {
    public func prepare(_ source: ExtensionInstallSource) async throws(ExtensionInstallError) -> PendingExtension {
        if case .chromeWebStore(let storeID) = source,
           let existing = installed.first(where: { $0.origin == .chromeWebStore(storeID) }) {
            throw .alreadyInstalled(existing.name)
        }
        return try await stage(source, replacing: nil)
    }

    public func commit(_ pending: PendingExtension) async throws(ExtensionInstallError) {
        guard staged.removeValue(forKey: pending.id) != nil else { throw .unpackFailed }
        let installID = pending.replacing ?? UUID()
        unload(installID)
        do {
            try files.promote(staged: pending.id, to: installID)
        } catch {
            files.deleteStaging(pending.id)
            throw .unpackFailed
        }
        var record = installed.first { $0.id == installID }
            ?? InstalledExtension(id: installID, manifest: pending.manifest, origin: pending.origin)
        record.refresh(from: pending.manifest)
        record.isEnabled = true
        if let position = installed.firstIndex(where: { $0.id == installID }) {
            installed[position] = record
        } else {
            installed.append(record)
        }
        await load(record)
        persist()
        if let failure = failures[installID] { throw .loadFailed(failure) }
    }

    public func discard(_ pending: PendingExtension) {
        staged[pending.id] = nil
        files.deleteStaging(pending.id)
    }

    /// Store extensions only: a folder or file has nowhere to update from.
    public func update(_ id: UUID) async throws(ExtensionInstallError) {
        guard let record = installed.first(where: { $0.id == id }),
              case .chromeWebStore(let storeID) = record.origin else { throw .notUpdatable }
        let pending = try await stage(.chromeWebStore(storeID), replacing: id)
        try await commit(pending)
    }

    private func stage(
        _ source: ExtensionInstallSource, replacing: UUID?
    ) async throws(ExtensionInstallError) -> PendingExtension {
        let stagingID = UUID()
        let directory = files.stagingDirectory(stagingID)
        try await ExtensionUnpacker.unpack(source, into: directory)
        let manifest: ExtensionManifestSummary
        do {
            manifest = Self.summary(of: try await WKWebExtension(resourceBaseURL: directory))
        } catch {
            files.deleteStaging(stagingID)
            throw .invalidManifest(error.localizedDescription)
        }
        let pending = PendingExtension(
            id: stagingID, manifest: manifest, origin: Self.origin(of: source), replacing: replacing
        )
        staged[stagingID] = pending
        return pending
    }

    private static func origin(of source: ExtensionInstallSource) -> ExtensionOrigin {
        switch source {
        case .chromeWebStore(let id): .chromeWebStore(id)
        case .folder: .folder
        case .archive: .archive
        }
    }
}
