import RedentDesign
import RedentKit
import SwiftUI

/// A keyboard-first command palette. Execution is delegated to the injected
/// model handler so this view has no browser or WebKit dependency.
public struct CommandBarView: View {
    @Bindable private var model: CommandBarModel
    private let space: BrowserSpace?
    private let dismissRequest: Int
    private let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @State private var appeared = false
    @State private var isClosing = false

    /// - Parameter dismissRequest: bumped by a click outside the panel.
    public init(
        model: CommandBarModel, space: BrowserSpace? = nil,
        dismissRequest: Int = 0, onDismiss: @escaping () -> Void
    ) {
        _model = Bindable(model)
        self.space = space
        self.dismissRequest = dismissRequest
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchField
            if appeared && !isClosing {
                Rectangle().fill(Palette.hairline).frame(height: Metric.hairWidth)
                CommandBarResults(model: model, onRun: { row in run { await model.execute(row) } })
                    .transition(.opacity)
            }
        }
        .frame(width: 620)
        .animation(.snappy(duration: 0.14), value: model.rows.count)
        .background { FloatingPanelSurface(space: space) }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.32), radius: 32, y: 16)
        .modifier(FloatingPanelMotion(revealed: appeared, isClosing: isClosing, reduceMotion: reduceMotion))
        .padding(.horizontal, 20)
        .defaultFocus($isFocused, true)
        .task(appear)
        .task(id: isClosing, finishClosing)
        .onChange(of: dismissRequest) { _, _ in dismissAnimated() }
        .onExitCommand(perform: dismissAnimated)
        .onChange(of: model.selectedIndex) { _, _ in announceSelection() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Command Center")
        .accessibilityAddTraits(.isModal)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.chromeSecondaryText)
                .accessibilityHidden(true)
            TextField("Search tabs, websites, actions…", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundStyle(Palette.chromeText)
                .focused($isFocused)
                .accessibilityLabel("Search tabs, websites, and actions")
                .onSubmit { run { await model.executeSelected() } }
                .onKeyPress(.downArrow) { model.moveSelection(by: 1); return .handled }
                .onKeyPress(.upArrow) { model.moveSelection(by: -1); return .handled }
                .onKeyPress(.escape) { dismissAnimated(); return .handled }
            Button { run { await model.executeSelected() } } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.chromeText)
                    .frame(width: 32, height: 32)
                    .background(Palette.chromeFill, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("Run selection")
        }
        .padding(.horizontal, 17)
        .frame(height: FloatingNewTabView.fieldHeight)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }

    /// Runs a row, and closes the bar unless the row only filled the field.
    private func run(_ body: @escaping @MainActor () async -> Bool) {
        Task {
            if await body() { onDismiss() } else { isFocused = true }
        }
    }

    private func dismissAnimated() {
        guard !isClosing else { return }
        guard !reduceMotion else { onDismiss(); return }
        withAnimation(.easeIn(duration: 0.16)) { isClosing = true }
    }

    /// Tied to the view's lifetime, so a bar already gone never closes the next one.
    private func finishClosing() async {
        guard isClosing else { return }
        try? await Task.sleep(for: .milliseconds(160))
        guard !Task.isCancelled else { return }
        onDismiss()
    }

    private func appear() async {
        if reduceMotion { appeared = true }
        else { withAnimation(.easeOut(duration: 0.20)) { appeared = true } }
        await Task.yield()
        isFocused = true
    }

    private func announceSelection() {
        guard let row = model.selectedRow else { return }
        AccessibilityNotification.Announcement("\(row.title), \(row.subtitle)").post()
    }
}
