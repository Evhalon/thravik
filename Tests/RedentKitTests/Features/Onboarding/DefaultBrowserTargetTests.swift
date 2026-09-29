import Foundation
import RedentKit
import Testing

struct DefaultBrowserTargetTests {
    @Test
    func differentCopiesAreNotTheSameDefaultBrowser() {
        let installed = URL(fileURLWithPath: "/Applications/Thravik.app")
        let development = URL(fileURLWithPath: "/tmp/Thravik.app")

        #expect(!DefaultBrowserTarget.matches(handlerURL: installed, bundleURL: development))
    }

    @Test
    func matchingBundleIsTheDefaultBrowser() {
        let bundle = URL(fileURLWithPath: "/Applications/Thravik.app")

        #expect(DefaultBrowserTarget.matches(handlerURL: bundle, bundleURL: bundle))
    }
}
