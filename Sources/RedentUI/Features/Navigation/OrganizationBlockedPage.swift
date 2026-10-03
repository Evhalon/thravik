import RedentDesign
import SwiftUI

struct OrganizationBlockedPage: View {
    let url: URL
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.gutter) {
            HStack(spacing: Metric.gutter) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Palette.danger)
                Text("Site blocked")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Palette.chromeText)
            }
            Text("Your organization does not allow visiting \(host).")
                .foregroundStyle(Palette.chromeSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer(minLength: Metric.gutter)
                Button("Close Tab", action: dismiss)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(28)
        .frame(maxWidth: 540, alignment: .leading)
        .floatingGlass(in: RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.canvas)
    }

    private var host: String { url.host ?? "this site" }
}
