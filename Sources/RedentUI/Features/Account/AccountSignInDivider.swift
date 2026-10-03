import RedentDesign
import SwiftUI

struct AccountSignInDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Palette.hairline).frame(height: Metric.hairWidth)
            Text("or").font(.system(size: 11)).foregroundStyle(Palette.chromeSecondaryText)
            Rectangle().fill(Palette.hairline).frame(height: Metric.hairWidth)
        }
    }
}
