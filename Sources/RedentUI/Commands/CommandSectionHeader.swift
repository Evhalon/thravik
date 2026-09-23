import SwiftUI

/// "Tabs", "Actions": the quiet label over a run of rows of one kind.
struct CommandSectionHeader: View {
    static let height: CGFloat = 24

    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .frame(height: Self.height, alignment: .bottomLeading)
            .accessibilityAddTraits(.isHeader)
    }
}
