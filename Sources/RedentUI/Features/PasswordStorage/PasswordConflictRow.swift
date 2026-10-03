import RedentKit
import SwiftUI

struct PasswordConflictRow: View {
    let conflict: PasswordConflict
    let model: PasswordStorageModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(conflict.label)
            HStack {
                Button("Use This Mac's Change") { Task { await model.resolve(id: conflict.id, keepingLocal: true) } }
                Button("Discard Local Change and Use Cloud") {
                    Task { await model.resolve(id: conflict.id, keepingLocal: false) }
                }
            }
        }
    }
}
