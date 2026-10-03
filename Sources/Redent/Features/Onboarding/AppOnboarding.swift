import Foundation
import RedentKit
import RedentUI

@MainActor
final class AppOnboarding {
    private static let importReceiptKey = "onboarding.browser-import-receipt.v1"
    let model: OnboardingModel
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let key = "onboarding.completed.v1"
        model = OnboardingModel(isComplete: defaults.bool(forKey: key))
        model.importReceipt = Self.loadImportReceipt(from: defaults)
        model.onFinish = { defaults.set(true, forKey: key) }
        model.configureDemoAccountFactory { Self.makeDemoAccount() }
        model.sound = OnboardingAudio()
        let soundKey = "onboarding.sound-enabled.v1"
        model.soundEnabled = defaults.object(forKey: soundKey) as? Bool ?? true
        model.onSoundPreferenceChanged = { defaults.set($0, forKey: soundKey) }
    }

    func restartReal() {
        defaults.set(false, forKey: "onboarding.completed.v1")
        model.startReal()
    }

    func recordImport(_ receipt: BrowserImportReceipt) {
        guard !model.isDemo, let data = try? JSONEncoder().encode(receipt) else { return }
        model.importReceipt = receipt
        defaults.set(data, forKey: Self.importReceiptKey)
    }

    private static func loadImportReceipt(from defaults: UserDefaults) -> BrowserImportReceipt? {
        guard let data = defaults.data(forKey: importReceiptKey) else { return nil }
        return try? JSONDecoder().decode(BrowserImportReceipt.self, from: data)
    }

    private static func makeDemoAccount() -> AccountModel {
        let authentication = DemoAccountAuthenticator()
        let account = AccountModel(authentication: authentication,
                                   sessions: DemoAccountSessionStore(), google: authentication)
        account.presentGoogle = { _ in
            guard let callback = URL(string: "redent://demo-account/callback") else {
                throw AccountError.invalidConfiguration
            }
            return callback
        }
        return account
    }
}
