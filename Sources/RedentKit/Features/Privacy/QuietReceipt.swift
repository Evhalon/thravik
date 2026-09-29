import Foundation

/// What Quiet mode did on the page on screen, so the quiet is visible rather
/// than taken on faith. Counts only — never which banner or which video.
public struct QuietReceipt: Sendable, Equatable {
    public var declinedCookieBanners: Int
    public var stoppedAutoplays: Int

    public init(declinedCookieBanners: Int = 0, stoppedAutoplays: Int = 0) {
        self.declinedCookieBanners = declinedCookieBanners
        self.stoppedAutoplays = stoppedAutoplays
    }

    public var isEmpty: Bool { declinedCookieBanners == 0 && stoppedAutoplays == 0 }
}
