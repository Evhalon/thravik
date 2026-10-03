import SwiftUI

struct TestingSettingsPane: View {
    let restartOnboarding: (@MainActor () -> Void)?
    let restartRealOnboarding: (@MainActor () -> Void)?
    let simulateStaleTabs: (@MainActor () -> Void)?
    let onDismiss: () -> Void

    var body: some View {
        SettingsSection("Tidy Tabs") {
            Text("Backdates background tabs in the current Space by eight days, then re-checks for a tidy suggestion.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Button("Simulate stale tabs", systemImage: "archivebox") {
                simulateStaleTabs?()
            }
            .buttonStyle(.bordered)
            .disabled(simulateStaleTabs == nil)
        }
        SettingsSection("Onboarding") {
            VStack(alignment: .leading, spacing: 12) {
                realSetup
                Divider().padding(.vertical, 8)
                demoSetup
            }
        }
    }

    private var realSetup: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Run setup with real browser import and your account.")
            Button("Restart real onboarding", systemImage: "person.crop.circle") {
                guard let restartRealOnboarding else { return }
                onDismiss()
                restartRealOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(restartRealOnboarding == nil)
        }
    }

    private var demoSetup: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Replay the first-run experience for a client demo.")
            Text("Demo details and sign-in are simulated. Your workspace and account stay as they are.")
                .font(.caption).foregroundStyle(.secondary)
            Button("Restart onboarding demo", systemImage: "arrow.counterclockwise") {
                guard let restartOnboarding else { return }
                onDismiss()
                restartOnboarding()
            }
            .buttonStyle(.bordered)
            .disabled(restartOnboarding == nil)
        }
    }
}
