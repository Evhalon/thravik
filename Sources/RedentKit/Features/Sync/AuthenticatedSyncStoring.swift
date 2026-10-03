import Foundation

/// Implementations verify ciphertext before upload and before committing incoming cursors.
public protocol AuthenticatedSyncStoring: SyncLocalStoring {}
