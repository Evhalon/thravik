import RedentDesign
import SwiftUI

/// A tappable row that opens another sheet from Settings (vault, import).
struct SettingsLinkRow: View {
    private let title: String
    private let systemImage: String
    private let action: () -> Void

    init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Metric.tightGutter + 2) {
                Image(systemName: systemImage)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.chromeText)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            .padding(.horizontal, 8)
            .frame(height: 36)
            .background {
                RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                    .fill(Palette.chromeFill)
            }
        }
        .buttonStyle(.plain)
    }
}
