import AppKit
import RedentKit
import SwiftUI

/// A compact field that takes one emoji. The system character palette writes
/// into it, which is how macOS exposes the emoji picker.
struct TabEmojiPicker: View {
    let current: String?
    let onSet: (String?) -> Void

    @State private var draft: String
    @FocusState private var isFocused: Bool

    /// Seeding here rather than in `onAppear` keeps `onChange` quiet, which
    /// would otherwise commit the current emoji and dismiss the popover.
    init(current: String?, onSet: @escaping (String?) -> Void) {
        self.current = current
        self.onSet = onSet
        _draft = State(initialValue: current ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Emoji Icon")
                .font(.system(size: 11, weight: .semibold))
            TextField("🎉", text: $draft)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onChange(of: draft, initial: false) { _, value in accept(value) }
            HStack {
                Button("Choose…") { NSApp.orderFrontCharacterPalette(nil) }
                Spacer()
                if current != nil {
                    Button("Remove", role: .destructive) { onSet(nil) }
                }
            }
        }
        .padding(12)
        .frame(width: 220)
        .onAppear {
            isFocused = true
            DispatchQueue.main.async { NSApp.orderFrontCharacterPalette(nil) }
        }
    }

    private func accept(_ value: String) {
        let latest = value.last.flatMap { TabCustomEmoji.validated(String($0)) }
        if let emoji = TabCustomEmoji.validated(value) ?? latest {
            if draft != emoji { draft = emoji }
            onSet(emoji)
            return
        }
        if !value.isEmpty { draft = "" }
    }
}

extension View {
    func tabEmojiPicker(for tab: any BrowserTab, isPresented: Binding<Bool>) -> some View {
        popover(isPresented: isPresented, arrowEdge: .bottom) {
            TabEmojiPicker(current: tab.snapshot.customEmoji) { emoji in
                tab.setCustomEmoji(emoji)
                isPresented.wrappedValue = false
            }
        }
    }
}
