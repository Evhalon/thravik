import SwiftUI

struct CommandBarRow: View {
    static let height: CGFloat = 40

    let row: CommandBarResult
    let query: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: row.symbol)
                .frame(width: 20)
                .foregroundStyle(isSelected ? .primary : .secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(MatchHighlight.attributed(row.title, matching: query)).lineLimit(1)
                Text(row.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            if isSelected { hint }
        }
        .padding(.horizontal, 10)
        .frame(height: Self.height)
        .background(isSelected ? Color.accentColor.opacity(0.18) : .clear,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    /// Says what return is about to do, so the lit row is never a guess.
    private var hint: some View {
        HStack(spacing: 4) {
            Text(actionLabel)
            Image(systemName: "return")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var actionLabel: String {
        switch row.source {
        case .command: "Run"
        case .tab: "Switch to Tab"
        case .space: "Go to Space"
        case .bookmark, .history, .directURL: "Open"
        case .search: "Search"
        }
    }
}
