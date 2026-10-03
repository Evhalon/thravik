import RedentDesign
import SwiftUI

struct AccountSettingsPane: View {
    @Bindable var model: AccountModel
    var passwords: PasswordStorageModel?
    var devices: DeviceMembershipModel?
    var workspace: WorkspaceSyncModel?
    var accountSyncManaged = false
    @State private var isConfirmingSignOut = false

    var body: some View {
        content
            .disabled(model.isBusy)
            .confirmationDialog("Are you sure you want to sign out?", isPresented: $isConfirmingSignOut,
                                titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { Task { await model.signOut() } }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Your account session will be removed from this Mac.")
            }
            .task { await model.restore() }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 22) {
            if model.session == nil {
                AccountSignInPage(model: model)
            } else {
                signedIn
                if let devices {
                    DeviceMembershipPane(model: devices)
                }
                if let workspace, !workspace.remoteTabs.isEmpty || workspace.message != nil {
                    RemoteTabsPane(model: workspace)
                }
            }
            if let passwords {
                PasswordStoragePane(model: passwords)
                    .managedPolicyLocked(accountSyncManaged)
            }
            if model.isBusy { ProgressView().controlSize(.small) }
            if let error = model.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.danger)
            }
        }
    }

    private var signedIn: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.session?.email ?? "Email unavailable")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.chromeText)
                Text(loginMethodLabel)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            Spacer(minLength: Metric.gutter)
            Button("Sign Out") { isConfirmingSignOut = true }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
    }

    private var loginMethodLabel: String {
        guard let method = model.session?.loginMethod else { return "Sign-in method unavailable" }
        switch method {
        case .email: return "Signed in with email"
        case .google: return "Signed in with Google"
        case .unknown: return "Sign-in method unavailable"
        }
    }
}
