import Foundation
import RedentKit

public actor CloudCredentialStore: CredentialStoring, PasswordConflictResolving {
    public typealias Configuration = CloudCredentialConfiguration
    public typealias Services = CloudCredentialServices

    private let configuration: Configuration
    private let projection: CloudCredentialProjection
    private var busy = false

    public init(configuration: Configuration) {
        self.configuration = configuration
        projection = CloudCredentialProjection(accountID: configuration.accountID,
                                               local: configuration.local, replica: configuration.replica,
                                               keys: configuration.keys)
    }

    public func allCredentials() async throws -> [Credential] {
        try begin()
        defer { busy = false }
        try await authorize()
        try await projection.restore()
        return try await configuration.local.allCredentials()
    }

    public func credentials(for origin: Origin) async throws -> [Credential] {
        try await allCredentials().filter { $0.origin.matches(origin) }
    }

    public func save(_ credential: Credential) async throws {
        try begin()
        defer { busy = false }
        try await authorize()
        try await projection.write(credential, id: credential.id)
    }

    public func delete(_ id: UUID) async throws {
        try begin()
        defer { busy = false }
        try await authorize()
        try await projection.write(nil, id: id)
    }

    public func markUsed(_ id: UUID) async throws {
        try begin()
        defer { busy = false }
        try await authorize()
        try await projection.restore()
        // Usage ranking is device-local and must never block autofill on network conflicts.
        try await configuration.local.markUsed(id)
    }

    public func importCredentials(_ credentials: [Credential]) async throws -> [Credential] {
        try begin()
        defer { busy = false }
        try await authorize()
        guard let session = try await configuration.sessions.load(), session.expiresAt > Date()
        else { throw SyncError.unauthorized }
        try await CloudCredentialRemotePuller(configuration: configuration).pullAll(session: session)
        try await projection.restore()
        let existing = try await configuration.local.allCredentials()
        try CloudCredentialImportValidation.validate(credentials, existing: existing)
        let fresh = CredentialImportDeduper.newcomers(in: credentials, alreadyHave: existing)
        try await projection.importFresh(fresh)
        return fresh
    }

    public func synchronize(session: AccountSession) async throws -> SyncRunResult {
        try begin()
        defer { busy = false }
        try await authorize()
        guard session.accountID == configuration.accountID else { throw SyncError.accountMismatch }
        try await projection.restore()
        let cursor = try await configuration.replica.cursor(accountID: session.accountID)
        let page = try await configuration.transport.pull(after: cursor, session: session)
        try Task.checkCancellation()
        try SyncPageValidation.validate(page, accountID: session.accountID, after: cursor)
        try await configuration.replica.apply(page, accountID: session.accountID)
        try await projection.restore()
        var uploaded = 0
        if !page.hasMore {
            let pending = try await configuration.replica.pending(accountID: session.accountID, limit: 100)
            for mutation in pending where mutation.identity.collection == "credentials" {
                try Task.checkCancellation()
                let accepted = try await configuration.transport.push(mutation, session: session)
                guard accepted.mutation == mutation, accepted.revision == mutation.expectedRevision + 1,
                      accepted.cursor > 0 else { throw SyncError.invalidResponse }
                try await configuration.replica.acknowledge(accepted)
                uploaded += 1
            }
        }
        try await projection.restore()
        let pending = try await configuration.replica.pending(accountID: session.accountID, limit: 1)
        return SyncRunResult(uploaded: uploaded, downloaded: page.records.count,
                             hasMore: page.hasMore || !pending.isEmpty)
    }

    public func conflicts() async throws -> [PasswordConflict] {
        try begin()
        defer { busy = false }
        try await authorize()
        return try await CloudCredentialConflictResolver(configuration: configuration).conflicts()
    }

    public func resolveConflict(id: UUID, keepingLocal: Bool) async throws {
        try begin()
        defer { busy = false }
        try await authorize()
        try await CloudCredentialConflictResolver(configuration: configuration)
            .resolve(id: id, keepingLocal: keepingLocal)
        try await projection.restore()
    }

    private func begin() throws {
        guard !busy else { throw SyncError.alreadyRunning }
        busy = true
    }

    private func authorize() async throws {
        guard let session = try await configuration.sessions.load() else { throw SyncError.unauthorized }
        guard session.accountID == configuration.accountID else { throw SyncError.accountMismatch }
        guard try await configuration.keys.load(accountID: configuration.accountID) != nil
        else { throw SyncError.unauthorized }
    }
}
