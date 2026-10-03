import RedentDesign
import RedentKit
import SwiftUI

struct MorningBriefSection: View {
    let events: [CalendarEvent]
    let onJoin: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TODAY")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Palette.chromeSecondaryText)
            if events.isEmpty {
                Text("No events today")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(events) { event in
                        MorningBriefRow(event: event, onJoin: onJoin)
                    }
                }
            }
        }
        .padding(.horizontal, 52)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
}
