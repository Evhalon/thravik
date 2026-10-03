import RedentDesign
import SwiftUI

/// Explains an empty Space and gives the user a first action.
struct SidebarEmptySpace: View {
    let openNewTab: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter + 2) {
            Text("No tabs in this Space")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.chromeText)
            Text("Open a tab to start browsing. Your bookmarks are in Favorites.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.chromeSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open a tab", action: openNewTab)
                .buttonStyle(.link)
                .font(.system(size: 11, weight: .medium))
            Spacer(minLength: 0)
        }
        .padding(.top, Metric.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
    }
}
