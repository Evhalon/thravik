import RedentDesign
import SwiftUI

struct CommandBarRow: View {
    static let height: CGFloat = 58

    let row: CommandBarResult
    let query: String
    let isSelected: Bool
    /// 1…9 when ⌘-that-number runs this row.
    let shortcutNumber: Int?
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 13) {
            icon
            VStack(alignment: .leading, spacing: 3) {
                Text(MatchHighlight.attributed(row.title, matching: query))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Palette.chromeText)
                    .lineLimit(1)
                if !row.subtitle.isEmpty {
                    Text(row.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.chromeSecondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 12)
        .frame(height: Self.height)
        .background { rowSurface }
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.14), value: isHovered)
        .animation(.snappy(duration: 0.18), value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.title), \(row.subtitle)")
        .accessibilityHint(actionLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
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

    /// A page shows its own icon; everything else the symbol for its kind.
    @ViewBuilder
    private var icon: some View {
        Group {
            if row.faviconData != nil || row.faviconHost != nil {
                FaviconView(data: row.faviconData, host: row.faviconHost, size: 20)
            } else {
                Image(systemName: row.symbol)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isSelected ? Palette.chromeText : Palette.chromeSecondaryText)
            }
        }
        .frame(width: 34, height: 34)
        .background(Palette.chromeFill, in: RoundedRectangle(cornerRadius: 10))
    }

    /// The lit row shows what return does: run it, or fill the field first.
    @ViewBuilder
    private var trailing: some View {
        if isSelected {
            Image(systemName: row.completion == nil ? "return" : "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.chromeText)
                .frame(width: 28, height: 24)
                .background(Palette.chromeFill, in: RoundedRectangle(cornerRadius: 7))
        } else if let shortcutNumber {
            Text("⌘\(shortcutNumber)")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(Palette.chromeSecondaryText.opacity(0.7))
        }
    }

    private var actionLabel: String {
        if row.completion != nil { return "Choose" }
        return switch row.source {
        case .command: "Run"
        case .tab: "Switch to Tab"
        case .space, .group: "Resume"
        case .window: "Switch to Window"
        case .webApp: "Open App"
        case .bookmark, .history, .directURL: "Open"
        case .search: "Search"
        }
    }
}
