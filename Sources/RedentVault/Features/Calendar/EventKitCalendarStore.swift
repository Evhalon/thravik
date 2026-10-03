import EventKit
import Foundation
import RedentKit

public actor EventKitCalendarStore: CalendarEventsProviding {
    /// Created on first use so a user who never turns meetings on never
    /// connects to the calendar daemon.
    private var connectedStore: EKEventStore?

    public init() {}

    public func authorizationStatus() async -> CalendarAuthorizationStatus {
        Self.status(EKEventStore.authorizationStatus(for: .event))
    }

    public func requestAccess() async -> CalendarAuthorizationStatus {
        do {
            let granted = try await store().requestFullAccessToEvents()
            return granted ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    public func events(in window: DateInterval) async throws -> [CalendarEvent] {
        let status = Self.status(EKEventStore.authorizationStatus(for: .event))
        guard status == .authorized else { throw CalendarEventsError.unauthorized }
        let eventStore = store()
        let predicate = eventStore.predicateForEvents(withStart: window.start, end: window.end, calendars: nil)
        return eventStore.events(matching: predicate).map(EventKitCalendarMapping.event)
    }

    public nonisolated func changes() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let relay = Task {
                for await _ in NotificationCenter.default.notifications(named: .EKEventStoreChanged) {
                    continuation.yield()
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in relay.cancel() }
        }
    }

    private func store() -> EKEventStore {
        if let connectedStore { return connectedStore }
        let created = EKEventStore()
        connectedStore = created
        return created
    }

    private static func status(_ value: EKAuthorizationStatus) -> CalendarAuthorizationStatus {
        switch value {
        case .fullAccess: .authorized
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied, .writeOnly: .denied
        @unknown default: .denied
        }
    }
}
