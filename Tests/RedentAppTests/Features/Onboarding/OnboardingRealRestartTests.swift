import Foundation
@testable import Redent
import Testing

@MainActor
struct OnboardingRealRestartTests {
    @Test func completedSetupSurvivesRelaunchAndInterruptedDemo() throws {
        let suite = "OnboardingCompletion.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let onboarding = AppOnboarding(defaults: defaults)
        onboarding.model.sound = nil
        #expect(!onboarding.model.isComplete)

        onboarding.model.finish()

        let relaunchedDefaults = try #require(UserDefaults(suiteName: suite))
        let relaunched = AppOnboarding(defaults: relaunchedDefaults)
        #expect(relaunched.model.isComplete)
        relaunched.model.startDemo()
        #expect(!relaunched.model.isComplete)
        #expect(AppOnboarding(defaults: relaunchedDefaults).model.isComplete)
    }

    @Test func realRestartDiscardsDemoAndPersistsUnfinishedSetup() throws {
        let suite = "OnboardingRealRestart.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "onboarding.completed.v1")
        let onboarding = AppOnboarding(defaults: defaults)
        onboarding.model.sound = nil
        onboarding.model.startDemo()
        #expect(onboarding.model.demoAccount != nil)

        onboarding.restartReal()

        #expect(!onboarding.model.isDemo)
        #expect(onboarding.model.demoAccount == nil)
        #expect(onboarding.model.step == .welcome)
        #expect(!onboarding.model.isComplete)
        #expect(!defaults.bool(forKey: "onboarding.completed.v1"))
        #expect(!AppOnboarding(defaults: defaults).model.isComplete)
        onboarding.model.finish()
        #expect(defaults.bool(forKey: "onboarding.completed.v1"))
        #expect(!onboarding.model.lastCompletionWasDemo)
    }
}
