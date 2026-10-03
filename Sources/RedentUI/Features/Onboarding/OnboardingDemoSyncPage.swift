import SwiftUI

struct OnboardingDemoSyncPage: View {
    let model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "lock.shield").font(.system(size: 44, weight: .light)).foregroundStyle(.orange)
            Text("Your spaces. Everywhere.").font(.system(size: 30, weight: .medium, design: .rounded))
            Text("Sign in on another Mac and unlock encrypted sync with your recovery code.")
                .foregroundStyle(.secondary)
            Label("Profile, Spaces, groups and pins", systemImage: "checkmark.circle")
            Label("Encrypted vault", systemImage: "checkmark.circle")
            Text("Demo preview. No vault is created or changed.").font(.caption).foregroundStyle(.secondary)
            Button("Continue") { model.advance() }.buttonStyle(.borderedProminent)
        }
    }
}
