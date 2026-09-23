import SwiftUI

/// The keyboard contract both search fields share: arrows walk the list, and
/// a completion lands in the field the moment its query answers.
struct SuggestionFieldBehavior: ViewModifier {
    let model: BrowserModel
    let source: AddressSuggestionsModel.Source
    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .onKeyPress(.downArrow) {
                model.moveSuggestionHighlight(by: 1, from: source) ? .handled : .ignored
            }
            .onKeyPress(.upArrow) {
                model.moveSuggestionHighlight(by: -1, from: source) ? .handled : .ignored
            }
            .onChange(of: model.suggestions.completion) { _, completion in
                guard isFocused, model.suggestions.isOpen(for: source), let completion else { return }
                FieldEditor.show(completion)
            }
    }
}

extension View {
    func suggestionFieldBehavior(
        _ model: BrowserModel, source: AddressSuggestionsModel.Source, isFocused: Bool
    ) -> some View {
        modifier(SuggestionFieldBehavior(model: model, source: source, isFocused: isFocused))
    }
}
