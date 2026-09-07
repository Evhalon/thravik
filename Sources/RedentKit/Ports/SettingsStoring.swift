import Foundation

public protocol SettingsStoring: Sendable {
    func load() -> BrowserSettings
    func save(_ settings: BrowserSettings)
}

public protocol SessionStoring: Sendable {
    func load() -> BrowserSession
    func save(_ session: BrowserSession)
    func loadRecoverable() throws -> BrowserSession
    func saveRecoverable(_ session: BrowserSession) throws
}

public extension SessionStoring {
    func loadRecoverable() throws -> BrowserSession { load() }
    func saveRecoverable(_ session: BrowserSession) throws { save(session) }
}

/// Structured, privacy-safe logging.
///
/// Implementations must never receive page content: callers pass identifiers
/// and redacted descriptions, never URLs with query strings or form values.
public protocol EventLogging: Sendable {
    func debug(_ message: @autoclosure () -> String)
    func notice(_ message: @autoclosure () -> String)
    func error(_ message: @autoclosure () -> String)
}
