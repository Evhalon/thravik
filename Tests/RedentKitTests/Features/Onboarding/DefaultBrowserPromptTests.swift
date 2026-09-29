import Testing
@testable import RedentKit

@Suite("Default browser offer")
struct DefaultBrowserPromptTests {
    private func input(
        installed: String? = "0.2.0",
        prompted: String? = nil,
        silenced: Bool = false,
        isDefault: Bool = false
    ) -> DefaultBrowserPrompt.Input {
        DefaultBrowserPrompt.Input(
            installedVersion: installed,
            lastPromptedVersion: prompted,
            isSilenced: silenced,
            isAlreadyDefault: isDefault
        )
    }

    @Test("A release that has not asked yet asks once")
    func asksOnFirstLaunch() {
        #expect(DefaultBrowserPrompt.shouldOffer(input()))
    }

    @Test("The same release never asks twice")
    func staysQuietWithinARelease() {
        #expect(!DefaultBrowserPrompt.shouldOffer(input(prompted: "0.2.0")))
    }

    @Test("An update asks again")
    func asksAfterAnUpdate() {
        #expect(DefaultBrowserPrompt.shouldOffer(input(installed: "0.3.0", prompted: "0.2.0")))
    }

    @Test("Already the default is never asked")
    func skipsWhenAlreadyDefault() {
        #expect(!DefaultBrowserPrompt.shouldOffer(input(isDefault: true)))
    }

    @Test("Don't ask again outlives every update")
    func respectsSilence() {
        #expect(!DefaultBrowserPrompt.shouldOffer(input(installed: "9.9.9", silenced: true)))
    }

    @Test("A build with no version asks at most once")
    func asksOnceWithoutAVersion() {
        #expect(DefaultBrowserPrompt.shouldOffer(input(installed: nil)))
        #expect(!DefaultBrowserPrompt.shouldOffer(input(installed: nil, prompted: "unversioned")))
    }
}
