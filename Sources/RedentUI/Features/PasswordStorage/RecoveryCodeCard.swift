import SwiftUI

struct RecoveryCodeCard: View {
    let code: String
    @Binding var saved: Bool
    let activate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Save this recovery code. It restores your encrypted vault if you forget the sync password.")
            Text(code).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            Toggle("I saved my recovery code", isOn: $saved)
            Button("Activate Encrypted Vault", action: activate).disabled(!saved)
        }
    }
}
