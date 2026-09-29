import RedentDesign
import RedentKit
import SwiftUI

/// One step in a tab's path. The transition is stated because "reloaded" and
/// "followed a link" are different answers to how the tab got here.
struct TabTimelineRow: View {
    let entry: NavigationEntry
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: Metric.gutter) {
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.displayTitle)
                    .font(.system(size: 12.5))
                    .lineLimit(1)
                Text("\(entry.transition.label) · \(entry.url.absoluteString)")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: Metric.tightGutter)
            Button(entry.restoreLabel, action: onRestore)
                .help(entry.hasLiveState
                      ? "Return to this page as it was left"
                      : "The saved page state is gone — this loads the address again")
        }
        .padding(.vertical, 2)
    }
}
