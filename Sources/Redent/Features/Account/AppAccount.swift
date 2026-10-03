import Foundation
import RedentKit
import RedentSync
import RedentUI
import RedentVault

@MainActor
final class AppAccount {
    let configuration: SupabaseConfiguration?
    let sessions: any AccountSessionStoring
    let model: AccountModel
    private let presentation = SystemAccountAuthentication()

    init(bundle: Bundle = .main) {
        let sessions = KeychainAccountSessionStore(service: KeychainNamespace.service("app.redent.account"))
        self.sessions = sessions
        let configuration = Self.configuration(bundle: bundle)
        self.configuration = configuration
        let authentication = configuration.map { SupabaseAccountAuthenticator(configuration: $0) }
        model = AccountModel(authentication: authentication, sessions: sessions, google: authentication)
        if authentication != nil {
            model.presentGoogle = { [presentation] url in try await presentation.authenticate(url: url) }
        }
    }

    func refreshIfNeeded() async {
        guard let session = model.session, session.expiresAt <= Date().addingTimeInterval(60) else { return }
        await model.restore()
    }

    func acceptCallback(_ url: URL) -> Bool {
        presentation.accept(url)
    }

    private static func configuration(bundle: Bundle) -> SupabaseConfiguration? {
        guard let endpoint = bundle.object(forInfoDictionaryKey: "RedentSupabaseURL") as? String,
              let key = bundle.object(forInfoDictionaryKey: "RedentSupabasePublishableKey") as? String,
              let url = URL(string: endpoint), let callback = URL(string: "redent://account/callback")
        else { return nil }
        return try? SupabaseConfiguration(supabaseURL: url, publishableKey: key, callbackURL: callback)
    }
}
