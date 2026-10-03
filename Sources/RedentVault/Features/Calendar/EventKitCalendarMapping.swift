import CoreGraphics
import EventKit
import Foundation
import RedentKit

enum EventKitCalendarMapping {
    static func event(_ ek: EKEvent) -> CalendarEvent {
        var details = CalendarEvent.Details()
        details.isAllDay = ek.isAllDay
        details.location = ek.location
        details.meetingURL = MeetingLinkExtractor.meetingURL(in: sources(ek))
        details.relatedURLs = relatedURLs(in: ek.notes, excluding: details.meetingURL)
        details.attendeesCount = ek.attendees?.count ?? 0
        details.calendarColorHex = colorHex(ek.calendar?.cgColor)
        details.isCancelled = ek.status == .canceled
        details.isDeclined = isDeclined(ek)
        return CalendarEvent(
            id: occurrenceID(ek),
            title: displayTitle(ek.title),
            start: ek.startDate,
            end: ek.endDate,
            details: details
        )
    }

    /// Every occurrence of a recurring event shares one item identifier, so
    /// the start date keeps two occurrences in one day distinct.
    static func occurrenceID(_ ek: EKEvent) -> String {
        "\(ek.calendarItemIdentifier)@\(Int(ek.startDate.timeIntervalSince1970))"
    }

    private static func sources(_ ek: EKEvent) -> [String] {
        [ek.url?.absoluteString, ek.location, ek.notes].compactMap { $0 }
    }

    private static func relatedURLs(in notes: String?, excluding meeting: URL?) -> [URL] {
        MeetingLinkExtractor.httpsURLs(in: notes ?? "").filter { $0 != meeting }
    }

    private static func displayTitle(_ title: String?) -> String {
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Event" : trimmed
    }

    private static func isDeclined(_ ek: EKEvent) -> Bool {
        ek.attendees?.contains { $0.isCurrentUser && $0.participantStatus == .declined } == true
    }

    private static func colorHex(_ color: CGColor?) -> String? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = color?.converted(to: space, intent: .defaultIntent, options: nil),
              let components = converted.components,
              components.count >= 3
        else { return nil }
        let red = Int((components[0] * 255).rounded())
        let green = Int((components[1] * 255).rounded())
        let blue = Int((components[2] * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
