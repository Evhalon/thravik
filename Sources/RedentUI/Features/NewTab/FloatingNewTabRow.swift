import RedentDesign
import RedentKit
import SwiftUI

struct FloatingNewTabRow: View {
    let item: FloatingNewTabItem
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 13) {
                icon
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Palette.chromeText)
                        .lineLimit(1)
                    if !item.detail.isEmpty {
                        Text(item.detail)
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.chromeSecondaryText)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "return")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Palette.chromeText)
                        .frame(width: 28, height: 24)
                        .background(Palette.chromeFill, in: RoundedRectangle(cornerRadius: 7))
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 58)
            .background { rowSurface }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.14), value: isHovered)
        .animation(.snappy(duration: 0.18), value: isSelected)
        .accessibilityLabel(item.detail.isEmpty ? item.title : "\(item.title), \(item.detail)")
        .accessibilityHint(actionLabel)
    }

    @ViewBuilder
    private var rowSurface: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        if isSelected {
            shape.fill(LinearGradient(
                colors: [Palette.accent.opacity(0.23), Palette.accent.opacity(0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .overlay { shape.strokeBorder(.white.opacity(0.15), lineWidth: 0.5) }
        } else if isHovered {
            shape.fill(Palette.chromeFill)
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let url = item.url, item.faviconData != nil {
            FaviconView(data: item.faviconData, host: Origin(url: url)?.displayHost, size: 20)
                .frame(width: 34, height: 34)
                .background(Palette.chromeFill, in: RoundedRectangle(cornerRadius: 10))
        } else {
            Image(systemName: item.symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isSelected ? Palette.chromeText : Palette.chromeSecondaryText)
                .frame(width: 34, height: 34)
                .background(Palette.chromeFill, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var actionLabel: String {
        switch item.target {
        case .tab: "Switch to tab"
        case .page: "Open page"
        case .blank: "Open blank tab"
        case .suggestion: "Open suggestion"
        }
    }
}
