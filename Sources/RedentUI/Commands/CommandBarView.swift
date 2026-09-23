import RedentDesign
import SwiftUI

/// A keyboard-first command palette. Execution is delegated to the injected
/// model handler so this view has no browser or WebKit dependency.
public struct CommandBarView: View {
    @Bindable private var model: CommandBarModel
    private let onDismiss: () -> Void
    @FocusState private var isFocused: Bool

    public init(model: CommandBarModel, onDismiss: @escaping () -> Void) {
        _model = Bindable(model)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider().opacity(0.35)
            results
        }
        .frame(width: 600)
        .animation(.snappy(duration: 0.14), value: model.rows.count)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 24, y: 10)
        .defaultFocus($isFocused, true)
        .task { await Task.yield(); isFocused = true }
        .onExitCommand(perform: onDismiss)
        .onChange(of: model.selectedIndex) { _, _ in announceSelection() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Command Center")
        .accessibilityAddTraits(.isModal)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Search tabs, websites, actions…", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 17))
                .focused($isFocused)
                .accessibilityLabel("Search tabs, websites, and actions")
                .onSubmit { execute() }
                .onKeyPress(.downArrow) { model.moveSelection(by: 1); return .handled }
                .onKeyPress(.upArrow) { model.moveSelection(by: -1); return .handled }
                .onKeyPress(.escape) { onDismiss(); return .handled }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }

    @ViewBuilder
    private var results: some View {
        if model.rows.isEmpty {
            Text("No matching tabs, pages, or actions")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 58)
                .transition(.opacity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                            item(row, at: index)
                        }
                    }
                    .padding(8)
                }
                .frame(height: resultsHeight)
                .onChange(of: model.selectedIndex) { _, index in
                    guard let index, model.rows.indices.contains(index) else { return }
                    withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(model.rows[index].id) }
                }
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
            .onTapGesture { run { await model.execute(row) } }
            .accessibilityAction { run { await model.execute(row) } }
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
        let visible = min(model.rows.count, 9)
        let headers = (0..<visible).filter { sectionTitle(at: $0) != nil }.count
        let rows = CGFloat(visible)
        return rows * CommandBarRow.height + max(rows - 1, 0) * 2 + 16
            + CGFloat(headers) * CommandSectionHeader.height
    }

    private func execute() {
        run { await model.executeSelected() }
    }

    /// Runs a row, and closes the bar unless the row only filled the field.
    private func run(_ body: @escaping @MainActor () async -> Bool) {
        Task {
            if await body() { onDismiss() } else { isFocused = true }
        }
    }

    private func announceSelection() {
        guard let row = model.selectedRow else { return }
        AccessibilityNotification.Announcement("\(row.title), \(row.subtitle)").post()
    }
}
