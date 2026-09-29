import Foundation

/// Structured, privacy-safe logging.
///
/// Implementations must never receive page content: callers pass identifiers
/// and redacted descriptions, never URLs with query strings or form values.
public protocol EventLogging: Sendable {
    func debug(_ message: @autoclosure () -> String)
    func notice(_ message: @autoclosure () -> String)
    func error(_ message: @autoclosure () -> String)
}
