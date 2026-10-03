import RedentDesign
import RedentKit
import SwiftUI

struct SidebarMeetingPill: View {
    @Bindable var model: BrowserModel

    var body: some View {
        if let event = visibleEvent, let url = event.meetingURL {
            HStack(spacing: Metric.tightGutter) {
                label
                Spacer(minLength: 0)
                prepareButton(event)
                joinButton(url)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background { chrome }
            .contextMenu {
                Button("Prepare meeting") { model.prepareMeeting(event) }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(model.meetings.countdown.pillText ?? event.title)
        }
    }

    private var visibleEvent: CalendarEvent? {
        guard model.settings.showsUpcomingMeetings else { return nil }
        guard model.meetings.countdown.state != .none else { return nil }
        return model.meetings.countdown.event
    }

    private var label: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 11, weight: .semibold))
            Text(model.meetings.countdown.pillText ?? "")
                .font(.system(size: 11.5, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(Palette.chromeText)
    }

    private func prepareButton(_ event: CalendarEvent) -> some View {
        Button { model.prepareMeeting(event) } label: {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.chromeSecondaryText)
                .frame(width: 22, height: 22)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help("Open meeting links in a new tab group")
    }

    private func joinButton(_ url: URL) -> some View {
        Button("Join") { model.joinMeeting(url) }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Palette.accent)
            .help("Open the meeting in a new tab")
    }

    private var chrome: some View {
        RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
            .fill(Palette.chromeFill)
            .overlay {
                RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: Metric.hairWidth)
            }
    }
}
