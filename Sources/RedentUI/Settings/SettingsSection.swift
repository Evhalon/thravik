import RedentDesign
import SwiftUI

/// Small-caps section label used by settings panes. Matches import-sheet type.
struct SettingsSection<Content: View>: View {
    private let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.tightGutter) {
            Text(title)
                .font(.system(size: 9.5, weight: .bold))
                .tracking(1)
                .foregroundStyle(Palette.chromeSecondaryText)
            content
        }
    }
}
