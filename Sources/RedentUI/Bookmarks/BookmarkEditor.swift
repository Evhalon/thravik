import RedentDesign
import RedentKit
import SwiftUI

/// Edits the user-owned label or address without changing bookmark metadata.
struct BookmarkEditor: View {
    enum Mode: Identifiable {
        case rename(Bookmark)
        case address(Bookmark)

        var id: UUID {
            switch self {
            case .rename(let bookmark), .address(let bookmark): bookmark.id
            }
        }

        var title: String {
            switch self {
            case .rename: "Rename Bookmark"
            case .address: "Edit Address"
            }
        }

        var initialValue: String {
            switch self {
            case .rename(let bookmark): bookmark.displayTitle
            case .address(let bookmark): bookmark.url.absoluteString
            }
        }

        var placeholder: String {
            switch self {
            case .rename: "Bookmark name"
            case .address: "https://example.com"
            }
        }

        var validationMessage: String {
            switch self {
            case .rename: "Enter a bookmark name."
            case .address: "Enter a valid http or https address."
            }
        }
    }

    let mode: Mode
    let onSave: (Mode, String) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var value: String
    @State private var errorMessage: String?

    init(mode: Mode, onSave: @escaping (Mode, String) async -> Bool) {
        self.mode = mode
        self.onSave = onSave
        _value = State(initialValue: mode.initialValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.gutter) {
            SheetHeading(title: mode.title, subtitle: "Changes apply immediately to this bookmark.")
            TextField(mode.placeholder, text: $value)
                .textFieldStyle(.roundedBorder)
            if let errorMessage {
                Text(errorMessage).font(.system(size: 11)).foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save", action: save).keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 390)
    }

    private func save() {
        Task {
            guard await onSave(mode, value) else {
                errorMessage = mode.validationMessage
                return
            }
            dismiss()
        }
    }
}
