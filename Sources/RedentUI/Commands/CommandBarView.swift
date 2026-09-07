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
        .frame(width: 560)
        .frame(maxHeight: 430)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 24, y: 10)
        .onAppear { isFocused = true }
        .onExitCommand(perform: onDismiss)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "command")
                .foregroundStyle(.secondary)
            TextField("Search tabs, Spaces, history, or commands", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .focused($isFocused)
                .onSubmit { execute() }
                .onKeyPress(.downArrow) { model.moveSelection(by: 1); return .handled }
                .onKeyPress(.upArrow) { model.moveSelection(by: -1); return .handled }
                .onKeyPress(.escape) { onDismiss(); return .handled }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var results: some View {
        if model.rows.isEmpty {
            Text("No matching commands or pages")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 58)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                            CommandBarRow(row: row, isSelected: model.selectedIndex == index)
                                .id(row.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    Task {
                                        await model.execute(row)
                                        onDismiss()
                                    }
                                }
                        }
                    }
                    .padding(8)
                }
                .onChange(of: model.selectedIndex) { _, index in
                    guard let index, model.rows.indices.contains(index) else { return }
                    withAnimation(.easeOut(duration: 0.12)) { proxy.scrollTo(model.rows[index].id) }
                }
            }
        }
    }

    private func execute() {
        Task {
            await model.executeSelected()
            onDismiss()
        }
    }
}
