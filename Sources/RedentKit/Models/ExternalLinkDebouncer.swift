import Foundation

/// Drops a link another app hands over a second time in quick succession.
///
/// Some mail clients pass the same click to the default browser twice; taken
/// literally, that is two tabs for one click.
public struct ExternalLinkDebouncer: Sendable {
    private let window: TimeInterval
    private var lastURL: URL?
    private var lastArrival: Date?

    public init(window: TimeInterval = 2) {
        self.window = window
    }

    /// - Returns: whether `url` should open, recording it if so.
    public mutating func admits(_ url: URL, at now: Date) -> Bool {
        if url == lastURL, let lastArrival, now.timeIntervalSince(lastArrival) < window {
            return false
        }
        lastURL = url
        lastArrival = now
        return true
    }
}
