import Foundation
import RedentKit

public enum WorkspaceStoreError: Error, Equatable, Sendable {
    case noWorkspaceData
    case corruptData
    case newerSchema(Int)
    case encodingFailed
}

// @unchecked Sendable: UserDefaults operations are thread-safe, and the
// last-write memo guards its own state with a lock.
public struct UserDefaultsWorkspaceStore: WorkspaceStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let lastWrite: LastWrite

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.lastWrite = LastWrite()
    }

    public func loadWorkspace() throws -> WorkspaceSnapshot {
        if let data = defaults.data(forKey: Keys.workspace) {
            let snapshot = try decodeSnapshot(data)
            return snapshot.schemaVersion == WorkspaceSnapshot.currentSchemaVersion
                ? snapshot : WorkspaceSnapshot(session: snapshot.session, revision: snapshot.revision)
        }
        guard let legacy = defaults.data(forKey: Keys.legacySession) else {
            return WorkspaceSnapshot(session: BrowserSession())
        }
        let session = try decodeLegacy(legacy)
        return WorkspaceSnapshot(session: session)
    }

    public func saveWorkspace(_ workspace: WorkspaceSnapshot) throws {
        let durable = WorkspaceSnapshot(session: workspace.session, revision: workspace.revision)
        guard let data = try? JSONEncoder().encode(durable) else { throw WorkspaceStoreError.encodingFailed }
        if let previous = defaults.data(forKey: Keys.workspace) {
            // A blob this store wrote itself already decoded cleanly on the way
            // in. Re-decoding it on every save put a full parse of the workspace
            // on the main thread between navigations.
            if !lastWrite.wrote(previous) { _ = try decodeSnapshot(previous) }
            defaults.set(previous, forKey: Keys.backup)
        } else if let legacy = defaults.data(forKey: Keys.legacySession) {
            _ = try decodeLegacy(legacy)
            defaults.set(legacy, forKey: Keys.backup)
        }
        defaults.set(data, forKey: Keys.workspace)
        lastWrite.record(data)
    }

    public func restoreBackup() throws -> WorkspaceSnapshot {
        guard let data = defaults.data(forKey: Keys.backup) else { throw WorkspaceStoreError.noWorkspaceData }
        do {
            return try decodeSnapshot(data)
        } catch WorkspaceStoreError.corruptData {
            return WorkspaceSnapshot(session: try decodeLegacy(data))
        } catch {
            throw error
        }
    }

    private func decodeSnapshot(_ data: Data) throws -> WorkspaceSnapshot {
        guard let envelope = try? JSONDecoder().decode(SchemaEnvelope.self, from: data) else {
            throw WorkspaceStoreError.corruptData
        }
        guard envelope.schemaVersion <= WorkspaceSnapshot.currentSchemaVersion else {
            throw WorkspaceStoreError.newerSchema(envelope.schemaVersion)
        }
        guard let snapshot = try? JSONDecoder().decode(WorkspaceSnapshot.self, from: data) else {
            throw WorkspaceStoreError.corruptData
        }
        guard snapshot.schemaVersion <= WorkspaceSnapshot.currentSchemaVersion else {
            throw WorkspaceStoreError.newerSchema(snapshot.schemaVersion)
        }
        return snapshot
    }

    private func decodeLegacy(_ data: Data) throws -> BrowserSession {
        guard let session = try? JSONDecoder().decode(BrowserSession.self, from: data) else {
            throw WorkspaceStoreError.corruptData
        }
        return session
    }
}

/// Remembers the last blob this process wrote, so the next save can skip
/// re-validating data it produced a moment ago.
// @unchecked Sendable: all access goes through the lock.
private final class LastWrite: @unchecked Sendable {
    private var data: Data?
    private let lock = NSLock()

    func record(_ value: Data) { lock.withLock { data = value } }
    func wrote(_ value: Data) -> Bool { lock.withLock { data == value } }
}

private struct SchemaEnvelope: Decodable {
    let schemaVersion: Int
}

private enum Keys {
    static let workspace = "app.redent.browser.workspace.v2"
    static let legacySession = "app.redent.browser.session"
    static let backup = "app.redent.browser.workspace.backup"
}
