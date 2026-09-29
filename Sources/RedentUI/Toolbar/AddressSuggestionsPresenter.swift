import SwiftUI

/// Keeps suggestions outside the sidebar's clipping and above the web view.
struct AddressSuggestionsPresenter: ViewModifier {
    let model: BrowserModel
    @State private var fieldFrame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .coordinateSpace(.named(AddressFieldFrameKey.space))
            .onPreferenceChange(AddressFieldFrameKey.self) { fieldFrame = $0 }
            .overlay(alignment: .topLeading) {
                if model.suggestions.isOpen(for: .addressBar), fieldFrame != .zero {
                    GeometryReader { geometry in
                        let width = min(max(fieldFrame.width, 440), max(geometry.size.width - 16, 0))
                        let left = min(max(fieldFrame.minX, 8), max(geometry.size.width - width - 8, 8))
                        SuggestionList(model: model)
                            .frame(width: width, alignment: .leading)
                            .offset(x: left, y: fieldFrame.maxY + 5)
                    }
                }
            }
    }
}
