import Foundation

public enum SyncPageValidation {
    public static func validate(_ page: SyncPage, accountID: UUID, after cursor: Int64) throws {
        guard cursor >= 0, page.records.count <= 100,
              !page.hasMore || !page.records.isEmpty else { throw SyncError.invalidResponse }
        var previous = cursor
        for record in page.records {
            try SyncMutationValidation.validate(record.mutation)
            guard record.mutation.identity.accountID == accountID else { throw SyncError.accountMismatch }
            guard record.cursor > previous, record.revision == record.mutation.expectedRevision + 1
            else { throw SyncError.invalidResponse }
            previous = record.cursor
        }
        guard page.nextCursor == previous else { throw SyncError.invalidResponse }
    }
}
