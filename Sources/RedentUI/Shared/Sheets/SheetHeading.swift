import RedentDesign
import SwiftUI

/// Quiet title + caption for management sheets. No system `.title2.bold()`.
struct SheetHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.chromeText)
            Text(subtitle)
                .font(.system(size: 11.5))
                .foregroundStyle(Palette.chromeSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
