import Foundation

/// Everything that can go wrong between "check for updates" and a staged app.
/// Each case carries enough to tell the user what to do next; none of them
/// carry a server response body, which could be anything.
public enum UpdateError: Error, Equatable, LocalizedError {
    case malformedFeedURL
    case feedUnreachable
    case feedStatus(Int)
    case noPublishedRelease
    case unreadableVersion(String)
    case noDiskImage
    case insecureDownload
    case downloadStatus(Int)
    case noAppInDiskImage
    case signatureRejected
    case identityMismatch
    case destinationNotWritable(String)
    case toolFailed(String, Int32)

    public var errorDescription: String? {
        switch self {
        case .malformedFeedURL: "The update source is not a valid address."
        case .feedUnreachable: "Could not reach the update server."
        case .feedStatus(let code): "The update server answered \(code)."
        case .noPublishedRelease: "There is no published release yet."
        case .unreadableVersion(let tag): "Release \(tag) is not a version this app can compare."
        case .noDiskImage: "That release ships no disk image."
        case .insecureDownload: "The download link is not HTTPS. Refusing it."
        case .downloadStatus(let code): "Downloading the update failed with \(code)."
        case .noAppInDiskImage: "The downloaded disk image holds no app."
        case .signatureRejected: "The downloaded app's signature did not verify."
        case .identityMismatch: "The downloaded app is a different app. Refusing it."
        case .destinationNotWritable(let path): "\(path) is not writable, so the app cannot replace itself."
        case .toolFailed(let tool, let status): "\(tool) exited with \(status)."
        }
    }
}
