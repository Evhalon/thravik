import RedentDesign
import SwiftUI

/// The modest "nothing here yet" pane shown instead of a blank list.
struct VaultEmptyState: View {
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: Metric.gutter) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(Palette.chromeSecondaryText)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
