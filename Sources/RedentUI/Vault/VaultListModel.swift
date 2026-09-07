import AppKit
import Foundation
import Observation
import RedentKit

/// Backs both vault lists — passwords and authenticator accounts — behind
/// the storage ports, never a concrete Keychain type.
@MainActor
@Observable
public final class VaultListModel {
    public private(set) var credentials: [Credential] = []
    public private(set) var accounts: [TOTPAccount] = []
    public private(set) var isLoading = false
    public private(set) var credentialError: String?
    public private(set) var authenticatorError: String?
    public var searchText = ""

    private let credentialStore: any CredentialStoring
    private let totpStore: any TOTPAccountStoring

    public init(credentialStore: any CredentialStoring, totpStore: any TOTPAccountStoring) {
        self.credentialStore = credentialStore
        self.totpStore = totpStore
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        credentialError = nil
        authenticatorError = nil
        await loadCredentials()
        await loadAccounts()
    }

    public var filteredCredentials: [Credential] {
        guard !searchText.isEmpty else { return credentials }
        return credentials.filter {
            $0.origin.displayHost.localizedCaseInsensitiveContains(searchText)
                || $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Filtered credentials grouped by host, alphabetically.
    public var groupedCredentials: [(host: String, items: [Credential])] {
        let groups = Dictionary(grouping: filteredCredentials, by: \.origin.displayHost)
        return groups.keys.sorted().map { (host: $0, items: groups[$0] ?? []) }
    }

    public func deleteCredential(_ id: UUID) async {
        try? await credentialStore.delete(id)
        credentials.removeAll { $0.id == id }
    }

    public func deleteAccount(_ id: UUID) async {
        try? await totpStore.delete(id)
        accounts.removeAll { $0.id == id }
    }

    public func copyUsername(_ credential: Credential) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(credential.username, forType: .string)
    }

    public func copyPassword(_ credential: Credential) {
        ConcealedPasteboard.copy(credential.password)
        Task { try? await credentialStore.markUsed(credential.id) }
    }

    private func loadCredentials() async {
        do {
            credentials = try await credentialStore.allCredentials()
        } catch {
            credentialError = "Redent could not open the password vault. Your Keychain data was not deleted."
        }
    }

    private func loadAccounts() async {
        do {
            accounts = try await totpStore.allAccounts()
        } catch {
            authenticatorError = "Redent could not open the authenticator vault. Your Keychain data was not deleted."
        }
    }
}
