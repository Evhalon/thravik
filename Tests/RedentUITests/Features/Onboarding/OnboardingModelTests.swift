import RedentKit
@testable import RedentUI
import Testing

@MainActor
struct OnboardingModelTests {
    @Test func profileRequiresNameAndTrimsIt() {
        let model = OnboardingModel(isComplete: false)
        model.advance()
        model.displayName = "   "
        model.advance()
        #expect(model.step == .profile)
        model.displayName = "  Ada  "
        model.purpose = "Study"
        model.advance()
        #expect(model.step == .space)
        #expect(model.profile == BrowserProfile(displayName: "Ada", purpose: "Study"))
    }

    @Test func restartAfterSpaceResumesAccountWithoutDuplicatingSpace() {
        let model = OnboardingModel(isComplete: false)
        model.resume(profile: BrowserProfile(displayName: "Ada", purpose: "Work"))
        #expect(model.step == .account)
        #expect(model.displayName == "Ada")
        model.advance()
        #expect(model.step == .sync)
        model.resume(profile: BrowserProfile(displayName: "Another", purpose: "Study"))
        #expect(model.step == .sync)
        #expect(model.displayName == "Ada")
    }

    @Test func finishPersistsOnceAndCanContinueWithoutAccount() {
        let model = OnboardingModel(isComplete: false)
        var saves = 0
        model.onFinish = { saves += 1 }
        model.finish()
        model.finish()
        #expect(model.isComplete)
        #expect(saves == 1)
    }

    @Test func demoRestartsFromWelcomeAndNeverPersistsCompletion() {
        let model = OnboardingModel(isComplete: true)
        var writes = 0
        model.onFinish = { writes += 1 }
        model.startDemo()
        #expect(model.isDemo)
        #expect(!model.isComplete)
        #expect(model.step == .welcome)
        model.resume(profile: BrowserProfile(displayName: "Real profile", purpose: "Work"))
        #expect(model.step == .welcome)
        #expect(model.displayName.isEmpty)
        model.advance()
        model.displayName = "Demo visitor"
        model.advance()
        model.advance()
        #expect(model.step == .importData)
        model.advance()
        #expect(model.step == .account)
        model.advance()
        #expect(model.step == .sync)
        model.advance()
        #expect(model.step == .defaultBrowser)
        model.finish()
        #expect(model.isComplete)
        #expect(!model.isDemo)
        #expect(model.lastCompletionWasDemo)
        #expect(writes == 0)
        model.startDemo()
        #expect(model.step == .welcome)
        #expect(model.displayName.isEmpty)
    }

    @Test func demoCannotReplaceAnUnfinishedRealOnboarding() {
        let model = OnboardingModel(isComplete: false)
        model.advance()
        model.startDemo()
        #expect(model.step == .profile)
        #expect(!model.isDemo)
    }

    @Test func completedSetupDoesNotResume() {
        let model = OnboardingModel(isComplete: true)
        model.resume(profile: BrowserProfile(displayName: "Ada", purpose: "Work"))
        #expect(model.isComplete)
        #expect(model.step == .welcome)
    }

    @Test func realFlowEndsAtDefaultBrowserChoice() {
        let model = OnboardingModel(isComplete: false)
        model.advance()
        model.displayName = "Ada"
        model.advance()
        model.advance()
        model.advance()
        model.advance()
        #expect(model.step == .sync)
        model.advance()
        #expect(model.step == .defaultBrowser)
    }
}
