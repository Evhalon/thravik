import RedentDesign
import RedentKit
import SwiftUI

/// Edits the user-owned label or address without changing bookmark metadata.
struct BookmarkEditor: View {
    enum Mode: Identifiable {
        case create(UUID)
        case folder(UUID)
        case rename(Bookmark)
        case address(Bookmark)

        var id: UUID {
            switch self {
            case .create(let id), .folder(let id): id
            case .rename(let bookmark), .address(let bookmark): bookmark.id
            }
        }

        var title: String {
            switch self {
            case .create: "Add Bookmark"
            case .folder: "New Folder"
            case .rename: "Rename Bookmark"
            case .address: "Edit Address"
            }
        }

        var initialTitle: String {
            switch self {
            case .create, .folder, .address: ""
            case .rename(let bookmark): bookmark.displayTitle
            }
        }

        var initialAddress: String {
            switch self {
            case .create, .folder, .rename: ""
            case .address(let bookmark): bookmark.url.absoluteString
            }
        }

        var validationMessage: String {
            switch self {
            case .create: "Enter a name and a valid http or https address."
            case .folder: "Enter a folder name."
            case .rename: "Enter a bookmark name."
            case .address: "Enter a valid http or https address."
            }
        }

        var showsTitle: Bool {
            if case .address = self { return false }
            return true
        }

        var showsAddress: Bool {
            if case .rename = self { return false }
            if case .folder = self { return false }
            return true
        }
    }

    let mode: Mode
    let onSave: (Mode, String, String) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var address: String
    @State private var errorMessage: String?

    init(mode: Mode, onSave: @escaping (Mode, String, String) async -> Bool) {
        self.mode = mode
        self.onSave = onSave
        _title = State(initialValue: mode.initialTitle)
        _address = State(initialValue: mode.initialAddress)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.gutter) {
            SheetHeading(title: mode.title, subtitle: "Changes apply immediately to this bookmark.")
            if mode.showsTitle {
                TextField("Bookmark name", text: $title).textFieldStyle(.roundedBorder)
            }
            if mode.showsAddress {
                TextField("https://example.com", text: $address).textFieldStyle(.roundedBorder)
            }
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
            guard await onSave(mode, title, address) else {
                errorMessage = mode.validationMessage
                return
            }
            dismiss()
        }
    }
}
