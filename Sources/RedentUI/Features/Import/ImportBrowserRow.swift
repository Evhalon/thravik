import RedentDesign
import RedentKit
import SwiftUI

/// One browser profile, picked independently of the others.
struct ImportBrowserRow: View {
    let browser: ImportableBrowser
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Metric.tightGutter + 2) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .foregroundStyle(isSelected ? Palette.accent : Palette.chromeSecondaryText)
            Text(browser.name).font(.system(size: 12.5))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Metric.tightGutter + 2)
        .frame(height: 30)
        .background {
            RoundedRectangle(cornerRadius: Metric.smallRadius, style: .continuous)
                .fill(isSelected ? Palette.accent.opacity(0.12) : .clear)
        }
        .contentShape(.rect)
        .onTapGesture(perform: onToggle)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
