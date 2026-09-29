import RedentKit

/// Opens each Keychain vault once at launch.
///
/// After an update from a build with another signature, every vault needs one
/// "Allow" before the new binary may read it, and each store then rewrites its
/// item for the new signature so the question never comes back. Reading them
/// here asks those questions together, right after launch, instead of one at a
/// time in the middle of a sign-in. On every later launch the reads are silent.
enum KeychainMigration {
    static func run(credentials: any CredentialStoring, authenticator: any TOTPAccountStoring) {
        // Sequential on purpose: two dialogs racing for focus read as a glitch.
        Task.detached(priority: .utility) {
            _ = try? await credentials.allCredentials()
            _ = try? await authenticator.allAccounts()
        }
    }
}
