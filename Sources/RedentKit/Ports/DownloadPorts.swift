import Foundation

/// Told about every change to a running download.
///
/// Implemented by the UI's download list; called by whatever engine is doing
/// the fetching. One call carries the whole item, so the observer never has to
/// reconstruct state from a stream of deltas.
@MainActor
public protocol DownloadObserving: AnyObject {
    func downloadChanged(_ item: DownloadItem)
}

/// What the download list can ask of the engine.
@MainActor
public protocol DownloadCommanding: AnyObject {
    func cancelDownload(_ id: UUID)
    /// Forgets a finished record. The file on disk is left alone.
    func forgetDownload(_ id: UUID)
}
