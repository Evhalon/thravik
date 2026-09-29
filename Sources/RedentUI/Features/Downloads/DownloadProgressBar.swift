import RedentDesign
import SwiftUI

/// The thin bar under a running download. A known size fills smoothly; an
/// unknown one uses the system's indeterminate sweep rather than a fake value.
struct DownloadProgressBar: View {
    let fraction: Double?

    var body: some View {
        if let fraction {
            Capsule()
                .fill(Palette.chromeSecondaryText.opacity(0.2))
                .overlay(alignment: .leading) { fill(fraction) }
                .frame(height: 3)
        } else {
            ProgressView()
                .progressViewStyle(.linear)
                .controlSize(.mini)
                .frame(height: 3)
        }
    }

    private func fill(_ fraction: Double) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Palette.accent)
                .frame(width: max(3, proxy.size.width * fraction))
                .animation(.smooth(duration: 0.45), value: fraction)
        }
    }
}
