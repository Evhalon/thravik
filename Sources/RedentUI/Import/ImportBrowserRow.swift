import RedentDesign
import RedentKit
import SwiftUI

/// One selectable browser profile.
struct ImportBrowserRow: View {
    let browser: ImportableBrowser
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: Metric.tightGutter + 2) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
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
        .onTapGesture(perform: onSelect)
    }
}
