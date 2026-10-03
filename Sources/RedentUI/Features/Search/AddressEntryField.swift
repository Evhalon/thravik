import RedentDesign
import SwiftUI

/// Keeps address editing and focus requests intact when navigation changes place.
struct AddressEntryField: View {
    @Bindable var model: BrowserModel
    @Binding var isFocused: Bool
    @FocusState private var hasFocus: Bool
    @State private var blurCommit: Task<Void, Never>?

    var body: some View {
        @Bindable var address = model.address
        return entry(text: $address.text)
            .onChange(of: address.text) { _, text in
                guard hasFocus, model.address.isUserChange(text) else { return }
                model.queryChanged(text, from: .addressBar)
            }
            .onChange(of: hasFocus) { _, focused in
                isFocused = focused
                handleFocus(focused)
            }
            .onChange(of: isFocused) { _, focused in hasFocus = focused }
            .onChange(of: model.centerSearchFocusEpoch) { _, _ in hasFocus = false }
            .onChange(of: model.chrome.addressFocusEpoch) { _, _ in hasFocus = true }
            .task {
                // A restored rail must attach its field before it can take focus.
                await Task.yield()
                guard !Task.isCancelled else { return }
                hasFocus = model.address.isEditing
            }
            .onDisappear { blurCommit?.cancel() }
    }

    private func entry(text: Binding<String>) -> some View {
        TextField("Search or enter address", text: text)
            .textFieldStyle(.plain)
            .font(.system(size: 12.5))
            .foregroundStyle(Palette.chromeText)
            .focused($hasFocus)
            .onSubmit { model.submitAddress() }
            .onExitCommand(perform: endEditing)
            .suggestionFieldBehavior(model, source: .addressBar, isFocused: hasFocus)
            .onKeyPress(.return, phases: .down) { press in
                guard press.modifiers.contains(.command) else { return .ignored }
                model.submitAddress(inNewTab: true)
                return .handled
            }
    }

    /// A suggestion tap lives outside this field, so blur would close the list
    /// before the click landed. Escape and a later blur still end the edit.
    private func handleFocus(_ focused: Bool) {
        blurCommit?.cancel()
        guard focused else {
            model.endPasteAndGoEditing(.address)
            blurCommit = Task { await commitBlur() }
            return
        }
        model.address.beginEditing(with: model.selectedTab)
        // After the field has taken the full URL, or the select lands on the
        // shorter display text it is about to replace.
        Task { @MainActor in
            await Task.yield()
            guard hasFocus else { return }
            FieldEditor.selectAll()
            model.beginPasteAndGoEditing(.address)
        }
    }

    private func commitBlur() async {
        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled else { return }
        endEditing()
    }

    /// Losing focus ends the edit, whatever took it away — a click on the page,
    /// another field, another window. Closing the dropdown alone left the field
    /// "being typed", so the compact host never came back.
    private func endEditing() {
        blurCommit?.cancel()
        model.endPasteAndGoEditing(.address)
        model.suggestions.close(from: .addressBar)
        model.address.cancelEditing(restoringFrom: model.selectedTab)
    }
}
