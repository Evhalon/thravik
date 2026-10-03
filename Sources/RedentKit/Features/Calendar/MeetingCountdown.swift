import Foundation

public struct MeetingCountdown: Sendable, Equatable {
    public enum State: Sendable, Equatable {
        case upcoming(minutes: Int)
        case live
        case none
    }

    public let event: CalendarEvent?
    public let state: State

    public static let none = MeetingCountdown(event: nil, state: .none)

    public init(event: CalendarEvent?, state: State) {
        self.event = event
        self.state = state
    }

    public static func evaluate(events: [CalendarEvent], now: Date) -> MeetingCountdown {
        let relevant = events.filter { isRelevant($0) }
        if let live = relevant.filter({ isLive($0, now: now) }).min(by: earlierStart) {
            return MeetingCountdown(event: live, state: .live)
        }
        guard let next = relevant.filter({ isUpcoming($0, now: now) }).min(by: earlierStart) else {
            return .none
        }
        return MeetingCountdown(event: next, state: .upcoming(minutes: minutesUntilStart(next, now: now)))
    }

    public var pillText: String? {
        guard let event else { return nil }
        switch state {
        case .upcoming(let minutes): return "\(event.title) · in \(minutes) min"
        case .live: return "\(event.title) · now"
        case .none: return nil
        }
    }

    private static let upcomingWindow: TimeInterval = 15 * 60

    /// Only joinable meetings count: a link-less block such as focus time
    /// would otherwise hide the call that starts inside it.
    private static func isRelevant(_ event: CalendarEvent) -> Bool {
        guard event.meetingURL != nil, !event.isAllDay else { return false }
        return !event.isCancelled && !event.isDeclined && event.end > event.start
    }

    private static func isLive(_ event: CalendarEvent, now: Date) -> Bool {
        event.start <= now && now < event.end
    }

    private static func isUpcoming(_ event: CalendarEvent, now: Date) -> Bool {
        let remaining = event.start.timeIntervalSince(now)
        return remaining > 0 && remaining <= upcomingWindow
    }

    private static func minutesUntilStart(_ event: CalendarEvent, now: Date) -> Int {
        max(1, Int(ceil(event.start.timeIntervalSince(now) / 60)))
    }

    private static func earlierStart(_ lhs: CalendarEvent, _ rhs: CalendarEvent) -> Bool {
        lhs.start < rhs.start
    }
}
