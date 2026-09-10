import RedentDesign
import SwiftUI

/// The find-in-page strip. Floats over the top-right of the page, the way
/// every other browser puts it, and is only in the tree while it is open.
struct FindBar: View {
    @Bindable var model: BrowserModel
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Metric.tightGutter) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Palette.chromeSecondaryText)

            TextField("Find on page", text: findQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(model.chrome.findFailed ? Palette.danger : Palette.chromeText)
                .frame(width: 180)
                .focused($isFocused)
                .onSubmit { model.findNext(forward: true) }
                .onExitCommand(perform: model.closeFindBar)
                .onChange(of: model.chrome.findQuery) { _, _ in model.findNext(forward: true) }
                .onChange(of: model.chrome.findFocusEpoch) { _, _ in isFocused = true }

            stepper(symbol: "chevron.up") { model.findNext(forward: false) }
            stepper(symbol: "chevron.down") { model.findNext(forward: true) }

            Button(action: model.closeFindBar) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.horizontal, Metric.gutter)
        .padding(.vertical, Metric.tightGutter)
        .floatingGlass(in: RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous))
        .onAppear { isFocused = true }
    }

    private var findQuery: Binding<String> {
        Binding(get: { model.chrome.findQuery }, set: { model.chrome.findQuery = $0 })
    }

    private func stepper(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .buttonStyle(PressScaleStyle())
        .disabled(model.chrome.findQuery.isEmpty)
    }
}
