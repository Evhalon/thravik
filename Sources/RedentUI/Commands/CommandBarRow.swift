import RedentDesign
import SwiftUI

struct CommandBarRow: View {
    static let height: CGFloat = 40

    let row: CommandBarResult
    let query: String
    let isSelected: Bool
    /// 1…9 when ⌘-that-number runs this row.
    let shortcutNumber: Int?

    var body: some View {
        HStack(spacing: 10) {
            icon.frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(MatchHighlight.attributed(row.title, matching: query)).lineLimit(1)
                Text(row.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 10)
        .frame(height: Self.height)
        .background(isSelected ? Color.accentColor.opacity(0.18) : .clear,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.title), \(row.subtitle)")
        .accessibilityHint(actionLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// A page shows its own icon; everything else the symbol for its kind.
    @ViewBuilder
    private var icon: some View {
        if row.faviconData != nil || row.faviconHost != nil {
            FaviconView(data: row.faviconData, host: row.faviconHost, size: 16)
        } else {
            Image(systemName: row.symbol)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if isSelected {
            hint
        } else if let shortcutNumber {
            Text("⌘\(shortcutNumber)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
    }

    /// Says what return is about to do, so the lit row is never a guess.
    private var hint: some View {
        HStack(spacing: 4) {
            Text(actionLabel)
            Image(systemName: row.completion == nil ? "return" : "chevron.right")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
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
