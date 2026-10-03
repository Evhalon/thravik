import Foundation

public enum CalendarEventsError: Error, Sendable, Equatable {
    case unauthorized
    case unavailable
}
