import RedentDesign
import RedentKit
import SwiftUI

struct ShortcutBindingsList: View {
    let bindings: ShortcutBindings
    @Binding var recordingID: ShortcutID?
    let onRestore: (ShortcutID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(ShortcutCategory.allCases) { category in
                SettingsSection(category.rawValue) {
                    ForEach(ShortcutID.ids(in: category)) { id in
                        ShortcutBindingRow(
                            row: ShortcutRowModel(
                                id: id,
                                chord: bindings.chord(for: id),
                                isCustomized: bindings.isCustomized(id),
                                isRecording: recordingID == id
                            ),
                            onRecord: { recordingID = id },
                            onRestore: { onRestore(id) }
                        )
                    }
                }
            }
        }
    }
}
