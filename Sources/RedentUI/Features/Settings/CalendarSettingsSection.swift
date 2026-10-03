import RedentDesign
import RedentKit
import SwiftUI

struct CalendarSettingsSection: View {
    @Binding var settings: BrowserSettings

    var body: some View {
        SettingsSection("CALENDAR") {
            SettingsToggleRow(
                "Show upcoming meetings",
                caption: "Asks for Calendar access, then shows a join pill before meetings and today’s events on New Tab.",
                isOn: $settings.showsUpcomingMeetings
            )
        }
    }
}
