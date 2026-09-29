import Foundation

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
