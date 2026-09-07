import Foundation

/// Chromium timestamps: microseconds since 1601-01-01 UTC (the Windows/WebKit
/// epoch), rather than Foundation's 2001 reference date.
enum ChromeEpoch {
    /// Seconds between the Chrome epoch (1601-01-01) and the Unix epoch (1970-01-01).
    private static let unixOffsetSeconds: Double = 11_644_473_600

    /// Converts a Chrome-epoch microsecond count to a `Date`.
    ///
    /// `0` means "never" in Chromium's schema, not 1601 — callers get
    /// `.distantPast` so it sorts before every real visit without implying a
    /// bogus 400-year-old timestamp.
    static func date(fromMicroseconds microseconds: Int64) -> Date {
        guard microseconds != 0 else { return .distantPast }
        let seconds = Double(microseconds) / 1_000_000 - unixOffsetSeconds
        return Date(timeIntervalSince1970: seconds)
    }

    /// Converts a `Date` to a Chrome-epoch microsecond count, the inverse of
    /// `date(fromMicroseconds:)`.
    static func microseconds(from date: Date) -> Int64 {
        let seconds = date.timeIntervalSince1970 + unixOffsetSeconds
        return Int64(seconds * 1_000_000)
    }
}
