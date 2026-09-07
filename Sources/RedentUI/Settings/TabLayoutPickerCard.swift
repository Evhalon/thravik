import RedentDesign
import RedentKit
import SwiftUI

/// A labelled preview card for one `TabLayout` option — a small mockup of
/// the chrome, so the choice is visual instead of a bare picker row.
struct TabLayoutPickerCard: View {
    let layout: TabLayout
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: Metric.tightGutter) {
                mockup
                Label(layout.label, systemImage: layout.symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Palette.chromeText)
                    .labelStyle(.titleAndIcon)
            }
            .padding(Metric.gutter)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Metric.smallRadius, style: .continuous)
                    .fill(isSelected ? Palette.accent.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metric.smallRadius, style: .continuous)
                    .strokeBorder(isSelected ? Palette.accent : Palette.hairline, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var mockup: some View {
        if layout == .sidebar {
            HStack(spacing: 2) {
                chrome.frame(width: 16)
                canvas
            }
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        } else {
            VStack(spacing: 2) {
                chrome.frame(height: 10)
                canvas
            }
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }

    private var chrome: some View { Rectangle().fill(Palette.chromeSecondaryText.opacity(0.3)) }
    private var canvas: some View { Rectangle().fill(Palette.canvas) }
}
