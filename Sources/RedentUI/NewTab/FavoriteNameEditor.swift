import RedentDesign
import SwiftUI

/// Lets a home-page favorite use a label that is more memorable than its URL.
struct FavoriteNameEditor: View {
    let tile: NewTabTile
    let onSave: (String) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var showsError = false

    init(tile: NewTabTile, onSave: @escaping (String) async -> Bool) {
        self.tile = tile
        self.onSave = onSave
        _name = State(initialValue: tile.title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.gutter) {
            SheetHeading(title: "Rename Favorite", subtitle: tile.host)
            TextField("Favorite name", text: $name)
                .textFieldStyle(.roundedBorder)
            if showsError {
                Text("Enter a name for this favorite.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.danger)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save", action: save).keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 350)
    }

    private func save() {
        Task {
            guard await onSave(name) else {
                showsError = true
                return
            }
            dismiss()
        }
    }
}
