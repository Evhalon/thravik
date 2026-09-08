import RedentDesign
import SwiftUI

/// The address bar: a glass pill that lights up when focused.
struct AddressField: View {
    @Bindable var model: BrowserModel
    @FocusState private var isFocused: Bool

    var body: some View {
        @Bindable var address = model.address
        return HStack(spacing: Metric.tightGutter + 1) {
            Image(systemName: securitySymbol)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(securityTint)

            TextField("Search or enter address", text: $address.text)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5))
                .foregroundStyle(Palette.chromeText)
                .focused($isFocused)
                .onSubmit(model.submitAddress)
                .onExitCommand {
                    model.suggestions.close(from: .addressBar)
                    model.address.cancelEditing(restoringFrom: model.selectedTab)
                }
                .onChange(of: isFocused) { _, focused in
                    guard focused else { return model.suggestions.close(from: .addressBar) }
                    model.address.beginEditing(with: model.selectedTab)
                }
                .onChange(of: address.text) { _, text in
                    guard isFocused, model.address.isUserChange(text) else { return }
                    model.queryChanged(text, from: .addressBar)
                }
                .onChange(of: model.centerSearchFocusEpoch) { _, _ in
                    isFocused = false
                }
                .onKeyPress(.downArrow) {
                    model.moveSuggestionHighlight(by: 1, from: .addressBar) ? .handled : .ignored
                }
                .onKeyPress(.upArrow) {
                    model.moveSuggestionHighlight(by: -1, from: .addressBar) ? .handled : .ignored
                }

            if model.selectedTab?.url != nil {
                BookmarkToggleButton(model: model)
            }
            if model.autofill.hasSuggestions {
                AutofillMenu(model: model)
            }
        }
        .padding(.horizontal, Metric.gutter)
        .frame(height: Metric.controlHeight)
        .background { pill }
        .overlay(alignment: .bottomLeading) { progressBar }
        .overlay(alignment: .topLeading) { dropdown }
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }

    private var pill: some View {
        let shape = RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
        return ZStack {
            shape.fill(.black.opacity(isFocused ? 0.26 : 0.16))
            shape.strokeBorder(
                LinearGradient(
                    colors: isFocused
                        ? [Palette.accent.opacity(0.8), Palette.accent.opacity(0.3)]
                        : [.white.opacity(0.20), .white.opacity(0.05)],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: isFocused ? 1.2 : Metric.hairWidth
            )
        }
        .shadow(color: Palette.accent.opacity(isFocused ? 0.28 : 0), radius: 9)
    }

    /// Anchored below the field, drawn above everything else in the window.
    @ViewBuilder
    private var dropdown: some View {
        if model.suggestions.isOpen(for: .addressBar) {
            SuggestionList(model: model)
                .frame(width: 360, alignment: .leading)
                .offset(y: Metric.controlHeight + 5)
                .zIndex(10)
        }
    }

    @ViewBuilder
    private var progressBar: some View {
        if let tab = model.selectedTab, tab.isLoading {
            GeometryReader { geometry in
                Capsule()
                    .fill(LinearGradient(colors: [Palette.accent.opacity(0.5), Palette.accent],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geometry.size.width * tab.progress, height: 2)
                    .animation(.easeOut(duration: 0.25), value: tab.progress)
            }
            .frame(height: 2)
            .padding(.horizontal, 6)
            .padding(.bottom, 1.5)
        }
    }

    private var isSecure: Bool { model.selectedTab?.origin?.scheme == "https" }

    private var securitySymbol: String {
        guard model.selectedTab?.url != nil else { return "magnifyingglass" }
        return isSecure ? "lock.fill" : "exclamationmark.triangle.fill"
    }

    private var securityTint: Color {
        guard model.selectedTab?.url != nil else { return Palette.chromeSecondaryText }
        return isSecure ? Palette.chromeSecondaryText : Palette.danger
    }
}
