import Foundation

public enum SyncMutationValidation {
    public static func validate(_ mutation: SyncMutation) throws {
        let collection = mutation.identity.collection
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789_")
        guard !collection.isEmpty, collection.count <= 32,
              collection.allSatisfy({ allowed.contains($0) }),
              mutation.expectedRevision >= 0, mutation.expectedRevision < Int64.max,
              mutation.encryptedPayload.count <= 180 * 1024,
              !mutation.encryptedPayload.isEmpty else { throw SyncError.invalidMutation }
    }
}
