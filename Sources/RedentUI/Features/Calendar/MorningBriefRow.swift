import RedentDesign
import RedentKit
import SwiftUI

struct MorningBriefRow: View {
    let event: CalendarEvent
    let onJoin: (URL) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(timeLabel)
                .font(.system(size: 12, weight: .medium).monospacedDigit())
                .foregroundStyle(Palette.chromeSecondaryText)
                .frame(width: 52, alignment: .leading)
            Text(event.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let url = event.meetingURL {
                Button("Join") { onJoin(url) }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.accent)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var timeLabel: String {
        if event.isAllDay { return "All day" }
        return event.start.formatted(date: .omitted, time: .shortened)
    }

    private var accessibilityLabel: String {
        event.meetingURL == nil ? "\(timeLabel), \(event.title)" : "\(timeLabel), \(event.title), Join"
    }
}
