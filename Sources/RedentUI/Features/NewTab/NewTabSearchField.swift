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
                .foregroundStyle(Palette.chromeSecondaryText)

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
                .suggestionFieldBehavior(model, source: .newTab, isFocused: isFocused)
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
                shape.fill(.black.opacity(0.20))
                shape.strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.22), .white.opacity(0.06)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: Metric.hairWidth
                )
            }
            .onTapGesture { isFocused = true }
        }
        .overlay(alignment: .topLeading) {
            dropdown.animation(.easeOut(duration: 0.12), value: model.suggestions.isOpen(for: .newTab))
        }
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
