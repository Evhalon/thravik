import RedentDesign
import RedentKit
import SwiftUI

/// Extra saved usernames for the current site. The capsule itself fills the
/// first; this menu is how the user picks a different one.
struct PasswordFillPicker: View {
    @Bindable var model: BrowserModel
    let fill: (Credential) -> Void

    var body: some View {
        Menu {
            ForEach(model.autofill.suggestions) { credential in
                Button {
                    fill(credential)
                } label: {
                    Text(credential.username.isEmpty ? credential.origin.displayHost : credential.username)
                }
            }
        } label: {
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Use a different saved login")
    }
}
