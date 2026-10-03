import Foundation
import RedentKit
import RedentUI
@testable import Redent
import Testing

@MainActor
struct OnboardingDemoAccountTests {
    @Test func demoAuthStaysLocalAndEachRestartGetsFreshAccount() async throws {
        let suite = "OnboardingDemoTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "onboarding.completed.v1")
        let onboarding = AppOnboarding(defaults: defaults)
        onboarding.model.sound = nil
        var finishWrites = 0
        onboarding.model.onFinish = { finishWrites += 1 }
        onboarding.model.startDemo()
        let first = try #require(onboarding.model.demoAccount)
        #expect(first.isConfigured)
        await exerciseLocalSignIn(first)
        let firstAccountID = try #require(first.session?.accountID)
        onboarding.model.finish()
        #expect(finishWrites == 0)

        onboarding.model.startDemo()
        let second = try #require(onboarding.model.demoAccount)
        #expect(first !== second)
        #expect(second.session == nil)
        await second.signInWithPassword(email: "demo@example.com", password: "anything")
        #expect(second.session?.accountID != firstAccountID)
        #expect(finishWrites == 0)
    }

    private func exerciseLocalSignIn(_ account: AccountModel) async {
        await account.signInWithGoogle()
        #expect(account.session != nil)
        await account.signOut()
        await account.requestEmailCode(email: "demo@example.com")
        await account.verifyEmailCode(email: "demo@example.com", code: "123456")
        #expect(account.session != nil)
        await account.signOut()
        await account.requestPasswordRecovery(email: "demo@example.com")
        await account.verifyPasswordRecoveryCode(email: "demo@example.com", code: "123456")
        await account.completePasswordRecovery(password: "new-password", confirmation: "new-password")
        #expect(account.session != nil)
    }
}
