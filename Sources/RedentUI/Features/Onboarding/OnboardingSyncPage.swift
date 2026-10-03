import RedentDesign
import SwiftUI

struct OnboardingSyncPage: View {
    @Bindable var onboarding: OnboardingModel
    @Bindable var passwords: PasswordStorageModel
    let workspace: WorkspaceSyncModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your spaces. Everywhere.")
                .font(.system(size: 30, weight: .medium, design: .rounded))
            Text("Unlock encrypted sync for your profile, Spaces, groups and pins. Other Macs’ tabs appear in Account settings.")
                .foregroundStyle(Palette.chromeSecondaryText)
            Text("On each Mac, sign in and enter your master sync password. Keep your recovery code as a backup in case you forget it.")
                .font(.callout)
            CloudPasswordVaultPane(model: passwords)
                .disabled(passwords.isBusy)
            if passwords.isBusy { ProgressView("Preparing encrypted sync…") }
            if let message = passwords.message { Text(message).font(.caption).foregroundStyle(Palette.danger) }
            if let message = workspace.message { Text(message).font(.caption).foregroundStyle(Palette.danger) }
            if passwords.availableModes.contains(.redentCloud) {
                passwordChoice
                Button("Continue") { onboarding.advance() }
                    .buttonStyle(.borderedProminent).disabled(passwords.isBusy)
            }
            Button("Set up sync later") { onboarding.advance() }
                .buttonStyle(.plain).foregroundStyle(Palette.chromeSecondaryText)
        }
        .task { await passwords.restore() }
    }

    private var passwordChoice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(passwords.selectedMode == .redentCloud ? "Cloud passwords enabled" : "Use cloud for new passwords") {
                Task { await passwords.select(.redentCloud, copyingCurrent: false) }
            }
            .disabled(passwords.isBusy || passwords.selectedMode == .redentCloud)
            Text("Existing passwords stay in their current provider. You can copy them explicitly in Settings.")
                .font(.caption).foregroundStyle(Palette.chromeSecondaryText)
        }
    }
}
