import RedentDesign
import RedentKit
import SwiftUI

struct HistoryBrowserRow: View {
    let entry: HistoryEntry
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(Palette.chromeSecondaryText)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayTitle).lineLimit(1)
                Text(entry.url.absoluteString)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(entry.lastVisit, style: .relative)
                .font(.system(size: 10.5))
                .foregroundStyle(Palette.chromeSecondaryText)
            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.chromeSecondaryText)
        }
        .contentShape(.rect)
        .onTapGesture(count: 2, perform: onOpen)
    }
}
