import RedentDesign
import SwiftUI

struct FloatingNewTabFieldInput {
    var submit: () -> Void
    var dismiss: () -> Void
    var move: (Int) -> KeyPress.Result
}

/// The floating new-tab query. Paste and Go attaches only while this field is focused.
struct FloatingNewTabField: View {
    @Bindable var model: BrowserModel
    @Binding var query: String
    var isFocused: FocusState<Bool>.Binding
    let input: FloatingNewTabFieldInput

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.chromeSecondaryText)
                .accessibilityHidden(true)
            TextField("Search or enter an address", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundStyle(Palette.chromeText)
                .focused(isFocused)
                .onSubmit(input.submit)
                .onChange(of: query) { _, text in
                    if isFocused.wrappedValue { model.queryChanged(text, from: .newTab) }
                }
                .onChange(of: model.suggestions.completion) { _, completion in
                    guard isFocused.wrappedValue, model.suggestions.isOpen(for: .newTab),
                          let completion else { return }
                    FieldEditor.show(completion)
                }
                .onKeyPress(.downArrow) { input.move(1) }
                .onKeyPress(.upArrow) { input.move(-1) }
                .onKeyPress(.escape) { input.dismiss(); return .handled }
            Button(action: input.submit) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.chromeText)
                    .frame(width: 32, height: 32)
                    .background(Palette.chromeFill, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("Open selection")
        }
        .padding(.horizontal, 17)
        .frame(height: FloatingNewTabView.fieldHeight)
    }
}
