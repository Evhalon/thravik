import Foundation
import RedentKit

actor FakeCalendarEventsProvider: CalendarEventsProviding {
    private(set) var fetchCount = 0
    private(set) var accessRequests = 0
    private var status: CalendarAuthorizationStatus
    private let grantsAccess: Bool
    private let stored: [CalendarEvent]
    private nonisolated let changeStream: AsyncStream<Void>
    private nonisolated let changeSink: AsyncStream<Void>.Continuation

    init(status: CalendarAuthorizationStatus = .authorized, grantsAccess: Bool = true, events: [CalendarEvent] = []) {
        self.status = status
        self.grantsAccess = grantsAccess
        self.stored = events
        (changeStream, changeSink) = AsyncStream<Void>.makeStream()
    }

    func authorizationStatus() async -> CalendarAuthorizationStatus { status }

    func requestAccess() async -> CalendarAuthorizationStatus {
        accessRequests += 1
        status = grantsAccess ? .authorized : .denied
        return status
    }

    func events(in window: DateInterval) async throws -> [CalendarEvent] {
        fetchCount += 1
        guard status == .authorized else { throw CalendarEventsError.unauthorized }
        return stored.filter { $0.start < window.end && $0.end > window.start }
    }

    nonisolated func changes() -> AsyncStream<Void> { changeStream }

    nonisolated func announceChange() { changeSink.yield() }
}
