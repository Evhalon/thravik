import RedentDesign
import SwiftUI

/// The Command Center's rows, laid out like the floating new-tab panel's.
struct CommandBarResults: View {
    let model: CommandBarModel
    let onRun: (CommandBarResult) -> Void

    var body: some View {
        if model.rows.isEmpty {
            Text("No matching tabs, pages, or actions")
                .font(.system(size: 13))
                .foregroundStyle(Palette.chromeSecondaryText)
                .frame(maxWidth: .infinity, minHeight: 58)
                .transition(.opacity)
        } else {
            list
        }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                        item(row, at: index)
                    }
                }
                .padding(9)
            }
            .scrollIndicators(.hidden)
            .frame(height: resultsHeight)
            .onChange(of: model.selectedIndex) { _, index in
                guard let index, model.rows.indices.contains(index) else { return }
                withAnimation(.easeOut(duration: 0.16)) { proxy.scrollTo(model.rows[index].id) }
            }
        }
    }

    @ViewBuilder
    private func item(_ row: CommandBarResult, at index: Int) -> some View {
        if let section = sectionTitle(at: index) {
            CommandSectionHeader(title: section)
        }
        CommandBarRow(row: row, query: model.query, isSelected: model.selectedIndex == index,
                      shortcutNumber: index < 9 ? index + 1 : nil)
            .id(row.id)
            .contentShape(Rectangle())
            .onTapGesture { onRun(row) }
            .accessibilityAction { onRun(row) }
    }

    /// Headings only while nothing is typed. Once the user types, rows are in
    /// best-guess order, and headings would chop that order into pieces.
    private func sectionTitle(at index: Int) -> String? {
        guard model.query.isEmpty else { return nil }
        let section = model.rows[index].source.section
        guard index == 0 || model.rows[index - 1].source.section != section else { return nil }
        return section
    }

    /// The panel hugs its results: a two-row answer should not sit in a
    /// panel sized for twenty.
    private var resultsHeight: CGFloat {
        let headers = model.rows.indices.filter { sectionTitle(at: $0) != nil }.count
        let rows = CGFloat(model.rows.count)
        let content = rows * CommandBarRow.height + max(rows - 1, 0) * 4 + 18
            + CGFloat(headers) * CommandSectionHeader.height
        return min(FloatingNewTabResults.maximumHeight, content)
    }
}
