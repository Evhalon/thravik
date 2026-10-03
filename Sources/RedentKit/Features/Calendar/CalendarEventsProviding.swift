import Foundation

public protocol CalendarEventsProviding: Sendable {
    func authorizationStatus() async -> CalendarAuthorizationStatus
    func requestAccess() async -> CalendarAuthorizationStatus
    func events(in window: DateInterval) async throws -> [CalendarEvent]
    /// Yields whenever the calendar database changes, so readers refetch on
    /// change instead of polling.
    func changes() -> AsyncStream<Void>
}
