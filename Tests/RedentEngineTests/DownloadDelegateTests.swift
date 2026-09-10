import Foundation
import RedentKit
import Testing
@testable import RedentEngine

/// The download hooks live in an extension, and WebKit reaches them by
/// selector. A signature that drifts would compile perfectly and simply never
/// be called — which is what this checks.
@MainActor
@Suite("Download delegate")
struct DownloadDelegateTests {
    /// Deliberately built from the string WebKit itself sends, not `#selector`:
    /// a name that drifts from WebKit's is precisely the failure being caught,
    /// and `#selector` would derive the drifted name and agree with itself.
    private func delegate() -> WebTabNavigationDelegate {
        WebTabNavigationDelegate(tab: WebTab(snapshot: TabSnapshot(), controller: nil))
    }

    @Test("WebKit can hand a navigation over as a download")
    func respondsToNavigationActionHook() {
        #expect(delegate().responds(to: NSSelectorFromString("webView:navigationAction:didBecomeDownload:")))
    }

    @Test("WebKit can hand a response over as a download")
    func respondsToNavigationResponseHook() {
        #expect(delegate().responds(to: NSSelectorFromString("webView:navigationResponse:didBecomeDownload:")))
    }

    @Test("A response the page cannot render is offered a policy")
    func respondsToResponsePolicy() {
        #expect(delegate().responds(
            to: NSSelectorFromString("webView:decidePolicyForNavigationResponse:decisionHandler:")
        ))
    }

    /// The session cannot be built without a live `WKDownload`, so the class
    /// itself is asked instead of an instance.
    @Test("The session answers every callback a download makes")
    func sessionImplementsTheDownloadDelegate() {
        let selectors = [
            "download:decideDestinationUsingResponse:suggestedFilename:completionHandler:",
            "downloadDidFinish:",
            "download:didFailWithError:resumeData:"
        ]
        for name in selectors {
            #expect(DownloadSession.instancesRespond(to: Selector(name)), "missing \(name)")
        }
    }
}
