import RedentDesign
import SwiftUI

/// Names a new collection without making the user leave the new-tab page.
struct FavoriteFolderEditor: View {
    let onSave: (String) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var showsError = false

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.gutter) {
            Text("New Favorites Folder")
                .font(.system(size: 16, weight: .semibold))
            Text("Drag favorites onto it to keep the new-tab page tidy.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.chromeSecondaryText)
            TextField("Folder name", text: $name)
                .textFieldStyle(.roundedBorder)
            if showsError {
                Text("Choose a unique name without a slash.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.danger)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create", action: save).keyboardShortcut(.defaultAction)
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
