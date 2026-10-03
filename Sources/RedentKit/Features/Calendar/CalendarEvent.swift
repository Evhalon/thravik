import Foundation

public struct CalendarEvent: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let start: Date
    public let end: Date
    public let isAllDay: Bool
    public let location: String?
    public let meetingURL: URL?
    public let relatedURLs: [URL]
    public let attendeesCount: Int
    public let calendarColorHex: String?
    public let isCancelled: Bool
    public let isDeclined: Bool

    public init(id: String, title: String, start: Date, end: Date, details: Details = Details()) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = details.isAllDay
        self.location = details.location
        self.meetingURL = details.meetingURL
        self.relatedURLs = details.relatedURLs
        self.attendeesCount = details.attendeesCount
        self.calendarColorHex = details.calendarColorHex
        self.isCancelled = details.isCancelled
        self.isDeclined = details.isDeclined
    }

    public var prepareURLs: [URL] {
        var urls: [URL] = []
        if let meetingURL { urls.append(meetingURL) }
        for url in relatedURLs where !urls.contains(url) { urls.append(url) }
        return urls
    }

    public struct Details: Sendable, Equatable {
        public var isAllDay = false
        public var location: String?
        public var meetingURL: URL?
        public var relatedURLs: [URL] = []
        public var attendeesCount = 0
        public var calendarColorHex: String?
        public var isCancelled = false
        public var isDeclined = false

        public init() {}
    }
}
