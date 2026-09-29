import RedentKit
import Testing
@testable import RedentUI

@Suite("Browser passkey access")
@MainActor
struct PasskeyAccessModelTests {
    @Test("Opening settings checks access without asking for permission")
    func refreshDoesNotPrompt() async {
        let authorizer = PasskeyAuthorizationFake()
        let model = PasskeyAccessModel(authorizer: authorizer)
        #expect(model.access == nil)
        await model.refresh()
        #expect(model.access == .notDetermined)
        #expect(await authorizer.requests == 0)
    }

    @Test("Only an undecided permission can raise the macOS prompt", arguments: [
        BrowserPasskeyAccess.authorized, .denied, .unavailable
    ])
    func settledAccessDoesNotPrompt(access: BrowserPasskeyAccess) async {
        let authorizer = PasskeyAuthorizationFake(access: access)
        let model = PasskeyAccessModel(authorizer: authorizer)
        await model.requestAccess()
        #expect(model.access == access)
        #expect(await authorizer.requests == 0)
        #expect(!model.isWorking)
    }

    @Test("A system decision reaches every window sharing the model", arguments: [
        BrowserPasskeyAccess.authorized, .denied
    ])
    func permissionAnswer(access: BrowserPasskeyAccess) async {
        let authorizer = PasskeyAuthorizationFake()
        let model = PasskeyAccessModel(authorizer: authorizer)
        let request = Task { await model.requestAccess() }
        while !model.isWorking { await Task.yield() }
        await model.requestAccess()
        await model.refresh()
        while await authorizer.requests == 0 { await Task.yield() }
        await authorizer.answer(access)
        await request.value
        #expect(model.access == access)
        #expect(await authorizer.requests == 1)
        #expect(!model.isWorking)
    }

    @Test("A decision changed in System Settings is reflected on refresh")
    func refreshAfterSystemSettings() async {
        let authorizer = PasskeyAuthorizationFake(access: .denied)
        let model = PasskeyAccessModel(authorizer: authorizer)
        await model.refresh()
        #expect(model.access == .denied)
        await authorizer.answer(.authorized)
        await model.refresh()
        #expect(model.access == .authorized)
    }

    @Test("Access is rechecked before prompting, even if Settings showed an old decision")
    func staleAccessDoesNotPrompt() async {
        let authorizer = PasskeyAuthorizationFake()
        let model = PasskeyAccessModel(authorizer: authorizer)
        await model.refresh()
        await authorizer.answer(.denied)
        await model.requestAccess()
        #expect(model.access == .denied)
        #expect(await authorizer.requests == 0)
    }
}
