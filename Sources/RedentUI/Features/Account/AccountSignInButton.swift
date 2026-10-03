import RedentDesign
import SwiftUI

struct AccountSignInButton: View {
    let title: String
    var mark: String?
    var prominent = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let mark {
                    Text(mark)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .frame(width: 18)
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(prominent ? Color.white : Palette.chromeText)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background { chrome }
        }
        .buttonStyle(PressScaleStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }

    private var chrome: some View {
        RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
            .fill(prominent ? Palette.accent.opacity(0.9) : Palette.chromeFill)
            .overlay { border }
    }

    @ViewBuilder
    private var border: some View {
        if !prominent {
            RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                .strokeBorder(Palette.hairline, lineWidth: Metric.hairWidth)
        }
    }
}
