import RedentDesign
import SwiftUI

/// "Tabs", "Actions": the quiet label over a run of rows of one kind.
struct CommandSectionHeader: View {
    static let height: CGFloat = 28

    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Palette.chromeSecondaryText)
            .padding(.horizontal, 14)
            .padding(.bottom, 3)
            .frame(height: Self.height, alignment: .bottomLeading)
            .accessibilityAddTraits(.isHeader)
    }
}
