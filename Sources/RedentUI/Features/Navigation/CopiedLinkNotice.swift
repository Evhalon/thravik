import Foundation

/// One copy of a link. Each copy is a new notice, so copying again restarts
/// the countdown rather than letting the first one's timer hide the second.
public struct CopiedLinkNotice: Identifiable, Equatable, Sendable {
    public let id = UUID()
    /// Tracking parameters were taken off before the link was copied.
    public let removedTracking: Bool
}
