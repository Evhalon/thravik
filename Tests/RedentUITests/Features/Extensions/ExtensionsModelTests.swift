import Foundation
import RedentKit
import RedentUI
import Testing

@Suite("Extensions settings")
@MainActor
struct ExtensionsModelTests {
    private let storeID = "ddkjiahejlhfcafbddmgiahcphecmpfh"

    @Test("Nothing is installed until the user confirms the review")
    func reviewBeforeInstall() async {
        let host = FakeExtensionHost()
        let model = ExtensionsModel(host: host)
        await model.review(.archive(URL(fileURLWithPath: "/tmp/a.crx")))
        #expect(model.pending?.manifest.name == "Blocker")
        #expect(model.installed.isEmpty)

        await model.confirmPending()?.value
        #expect(model.pending == nil)
        #expect(model.installed.map(\.name) == ["Blocker"])
    }

    @Test("The alert closing itself after Add does not cancel the install")
    func confirmSurvivesDismissal() async {
        let host = FakeExtensionHost()
        let model = ExtensionsModel(host: host)
        await model.review(.archive(URL(fileURLWithPath: "/tmp/a.crx")))
        let install = model.confirmPending()
        model.cancelPending()
        await install?.value
        #expect(host.discarded.isEmpty)
        #expect(model.installed.map(\.name) == ["Blocker"])
    }

    @Test("Cancelling the review throws the unpacked files away")
    func cancelDiscards() async {
        let host = FakeExtensionHost()
        let model = ExtensionsModel(host: host)
        await model.review(.archive(URL(fileURLWithPath: "/tmp/a.zip")))
        model.cancelPending()
        #expect(model.pending == nil)
        #expect(host.discarded.count == 1)
        #expect(model.installed.isEmpty)
    }

    @Test("A store link is turned into its id, and cleared once it reaches review")
    func storeLink() async throws {
        let host = FakeExtensionHost()
        let model = ExtensionsModel(host: host)
        model.storeLinkText = "https://chromewebstore.google.com/detail/ublock/\(storeID)"
        await model.addFromStoreLink()
        let id = try #require(ChromeWebStoreID(storeID))
        #expect(host.prepared == [.chromeWebStore(id)])
        #expect(model.storeLinkText.isEmpty)
    }

    @Test("Text that is not a store link never reaches the host")
    func rejectsGarbage() async {
        let host = FakeExtensionHost()
        let model = ExtensionsModel(host: host)
        model.storeLinkText = "ublock please"
        await model.addFromStoreLink()
        #expect(host.prepared.isEmpty)
        #expect(model.errorMessage != nil)
    }

    @Test("A failed download is reported and the link is kept to retry")
    func failureKeepsLink() async {
        let host = FakeExtensionHost()
        host.prepareFailure = .downloadFailed
        let model = ExtensionsModel(host: host)
        model.storeLinkText = storeID
        await model.addFromStoreLink()
        #expect(model.errorMessage == ExtensionInstallError.downloadFailed.message)
        #expect(model.storeLinkText == storeID)
    }

    @Test("Turning an extension off is reflected in the list")
    func toggle() async throws {
        let host = FakeExtensionHost()
        let model = ExtensionsModel(host: host)
        await model.review(.folder(URL(fileURLWithPath: "/tmp/ext")))
        await model.confirmPending()?.value
        let id = try #require(model.installed.first?.id)
        model.setEnabled(false, for: id)
        #expect(model.installed.first?.isEnabled == false)
    }
}
