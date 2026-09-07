import SwiftUI

struct CommandBarRow: View {
    let row: CommandBarResult
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: row.symbol)
                .frame(width: 20)
                .foregroundStyle(isSelected ? .primary : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title).lineLimit(1)
                Text(row.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(row.source.rawValue.capitalized)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isSelected ? Color.accentColor.opacity(0.18) : .clear,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
