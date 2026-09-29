import RedentDesign
import RedentKit
import SwiftUI

/// Offers saved logins for the current site. Filling is always a deliberate
/// choice — nothing is written into the page until an entry is picked, and the
/// form is never submitted for the user.
struct AutofillMenu: View {
    @Bindable var model: BrowserModel

    var body: some View {
        Menu {
            ForEach(model.autofill.suggestions) { credential in
                Button {
                    fill(credential)
                } label: {
                    Label(credential.username, systemImage: "person.crop.circle")
                }
            }
            Divider()
            Button("Manage Passwords…") { model.sheet = .passwords }
        } label: {
            Image(systemName: "key.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Palette.accent)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Fill a saved login")
    }

    private func fill(_ credential: Credential) {
        guard let tab = model.selectedTab else { return }
        Task {
            await tab.fillCredential(username: credential.username, password: credential.password)
            await model.autofill.credentialFilled(credential)
        }
    }
}
