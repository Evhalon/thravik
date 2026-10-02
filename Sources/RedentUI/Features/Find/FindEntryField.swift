import RedentDesign
import SwiftUI

struct FindEntryField: View {
    @Bindable var model: BrowserModel
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Find on page", text: query)
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(model.chrome.findFailed ? Palette.danger : Palette.chromeText)
            .frame(width: 180)
            .focused($isFocused)
            .onKeyPress(.return, phases: .down) { press in
                model.findNext(forward: !press.modifiers.contains(.shift))
                return .handled
            }
            .onExitCommand(perform: model.closeFindBar)
            .task(id: model.chrome.findFocusEpoch) { await focusAndSelect() }
            .accessibilityLabel("Find on page")
    }

    private var query: Binding<String> {
        Binding(get: { model.chrome.findQuery }, set: {
            model.chrome.findQuery = $0
            model.findQueryChanged()
        })
    }

    private func focusAndSelect() async {
        // Focusing the browser field first can erase a selected web input before its value is captured.
        guard !model.chrome.isCapturingFindSelection, model.chrome.isFindBarVisible else { return }
        isFocused = true
        await Task.yield()
        guard !Task.isCancelled, isFocused, !model.chrome.isCapturingFindSelection,
              model.chrome.isFindBarVisible else { return }
        FieldEditor.selectAll()
    }
}
