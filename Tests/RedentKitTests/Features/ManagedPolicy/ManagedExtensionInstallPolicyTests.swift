import Testing
@testable import RedentKit

@Suite("Managed extension install policy")
struct ManagedExtensionInstallPolicyTests {
    private let uBlock = "ddkjiahejlhfcafbddmgiahcphecmpfh"
    private let other = "nngceckbapebfimnlniiiahkandclblb"

    @Test("Unrestricted when policy omits extension controls")
    func unrestricted() throws {
        let id = try #require(ChromeWebStoreID(uBlock))
        #expect(ManagedExtensionInstallPolicy.allowsInstall(storeID: id, policy: ManagedPolicy()))
    }

    @Test("Disable extensions blocks unless allowlisted")
    func disableWithAllowlist() throws {
        let allowed = try #require(ChromeWebStoreID(uBlock))
        let blocked = try #require(ChromeWebStoreID(other))
        let policy = ManagedPolicy(disableExtensions: true, extensionAllowlist: [allowed.rawValue])
        #expect(ManagedExtensionInstallPolicy.allowsInstall(storeID: allowed, policy: policy))
        #expect(!ManagedExtensionInstallPolicy.allowsInstall(storeID: blocked, policy: policy))
    }
}
