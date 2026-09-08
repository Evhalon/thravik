import RedentDesign
import SwiftUI

/// The new tab's search field: the same job as the address bar, given the
/// prominence it deserves when it is the only thing on screen.
struct NewTabSearchField: View {
    @Bindable var model: BrowserModel
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: Metric.gutter) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isFocused ? Palette.accent : Palette.chromeSecondaryText)

            TextField("Search the web or type an address", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundStyle(Palette.chromeText)
                // A long query must scroll inside the pill, not wrap it into a
                // second line: the field is fixed height, so wrapped text is
                // clipped text.
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
                .focused($isFocused)
                .onSubmit(onSubmit)
                .onChange(of: text) { _, value in
                    guard isFocused else { return }
                    model.queryChanged(value, from: .newTab)
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused { model.suggestions.close(from: .newTab) }
                }
                .onKeyPress(.downArrow) {
                    model.moveSuggestionHighlight(by: 1, from: .newTab) ? .handled : .ignored
                }
                .onKeyPress(.upArrow) {
                    model.moveSuggestionHighlight(by: -1, from: .newTab) ? .handled : .ignored
                }
                .onExitCommand { model.suggestions.close(from: .newTab) }

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.chromeSecondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
        .background {
            let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
            ZStack {
                shape.fill(.black.opacity(isFocused ? 0.30 : 0.20))
                shape.strokeBorder(
                    LinearGradient(
                        colors: isFocused
                            ? [Palette.accent.opacity(0.85), Palette.accent.opacity(0.25)]
                            : [.white.opacity(0.22), .white.opacity(0.06)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: isFocused ? 1.4 : Metric.hairWidth
                )
            }
            .shadow(color: Palette.accent.opacity(isFocused ? 0.32 : 0), radius: 18, y: 4)
        }
        .animation(.easeOut(duration: 0.2), value: isFocused)
        .overlay(alignment: .topLeading) { dropdown }
        .padding(.horizontal, 40)
        .zIndex(3)
    }

    @ViewBuilder
    private var dropdown: some View {
        if model.suggestions.isOpen(for: .newTab) {
            SuggestionList(model: model)
                .offset(y: 58)
                .zIndex(10)
        }
    }
}
