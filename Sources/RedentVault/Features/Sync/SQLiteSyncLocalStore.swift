import Foundation
import RedentKit

public actor SQLiteSyncLocalStore: SyncLocalStoring {
    private let fileURL: URL
    private var storage: SyncDatabase?

    public init(fileURL: URL) { self.fileURL = fileURL }

    private func database() throws -> SyncDatabase {
        if let storage { return storage }
        let created = try SyncDatabase(fileURL: fileURL)
        storage = created
        return created
    }

    public func enqueue(_ mutation: SyncMutation) throws {
        try SyncMutationValidation.validate(mutation)
        let database = try database()
        let matches = try database.read("SELECT encoded FROM sync_outbox WHERE mutation_id=?",
                                        bindings: [.text(mutation.id.uuidString)]) {
            try database.decode(SyncMutation.self, row: $0)
        }
        if let existing = matches.first {
            guard existing == mutation else { throw SyncError.mutationCollision }
            return
        }
        let encoded = try JSONEncoder().encode(mutation).base64EncodedString()
        try database.connection.run("INSERT INTO sync_outbox(owner,mutation_id,encoded) VALUES(?,?,?)",
            bindings: [.text(mutation.identity.accountID.uuidString), .text(mutation.id.uuidString), .text(encoded)])
    }

    public func replacePending(_ mutation: SyncMutation, with replacement: SyncMutation?) throws {
        if let replacement {
            try SyncMutationValidation.validate(replacement)
            guard replacement.identity == mutation.identity else { throw SyncError.accountMismatch }
        }
        let database = try database()
        try database.transaction {
            let matches = try database.read("SELECT encoded FROM sync_outbox WHERE mutation_id=?",
                                            bindings: [.text(mutation.id.uuidString)]) {
                try database.decode(SyncMutation.self, row: $0)
            }
            guard matches.first == mutation else { throw SyncError.mutationCollision }
            try database.connection.run("DELETE FROM sync_outbox WHERE mutation_id=?",
                                        bindings: [.text(mutation.id.uuidString)])
            if let replacement {
                let encoded = try JSONEncoder().encode(replacement).base64EncodedString()
                try database.connection.run("INSERT INTO sync_outbox(owner,mutation_id,encoded) VALUES(?,?,?)",
                    bindings: [.text(replacement.identity.accountID.uuidString),
                               .text(replacement.id.uuidString), .text(encoded)])
            }
        }
    }

    public func pending(accountID: UUID, limit: Int) throws -> [SyncMutation] {
        let database = try database()
        return try database.read("SELECT encoded FROM sync_outbox WHERE owner=? ORDER BY sequence LIMIT ?",
                                 bindings: [.text(accountID.uuidString), .int(Int64(max(1, min(10_000, limit))))]) {
            try database.decode(SyncMutation.self, row: $0)
        }
    }

    public func acknowledge(_ record: SyncRemoteRecord) throws {
        let database = try database()
        let matches = try database.read("SELECT encoded FROM sync_outbox WHERE mutation_id=?",
                                        bindings: [.text(record.mutation.id.uuidString)]) {
            try database.decode(SyncMutation.self, row: $0)
        }
        guard let pending = matches.first, pending == record.mutation,
              record.revision == pending.expectedRevision + 1, record.cursor > 0
        else { throw SyncError.invalidResponse }
        try database.transaction {
            try database.persist(record)
            try database.connection.run("DELETE FROM sync_outbox WHERE mutation_id=?",
                                        bindings: [.text(pending.id.uuidString)])
        }
    }

    public func cursor(accountID: UUID) throws -> Int64 {
        let database = try database()
        return try database.read("SELECT cursor FROM sync_cursors WHERE owner=?",
                                 bindings: [.text(accountID.uuidString)]) { Int64($0.int(0)) }.first ?? 0
    }

    public func apply(_ page: SyncPage, accountID: UUID) throws {
        let previous = try cursor(accountID: accountID)
        try SyncPageValidation.validate(page, accountID: accountID, after: previous)
        let database = try database()
        try database.transaction {
            for record in page.records { try database.persist(record) }
            try database.connection.run("""
                INSERT INTO sync_cursors(owner,cursor) VALUES(?,?)
                ON CONFLICT(owner) DO UPDATE SET cursor=excluded.cursor
                """, bindings: [.text(accountID.uuidString), .int(page.nextCursor)])
        }
    }

    public func records(accountID: UUID) throws -> [SyncRemoteRecord] {
        let database = try database()
        return try database.read("SELECT encoded FROM sync_records WHERE owner=? ORDER BY collection,record_id",
                                 bindings: [.text(accountID.uuidString)]) {
            try database.decode(SyncRemoteRecord.self, row: $0)
        }
    }
}
