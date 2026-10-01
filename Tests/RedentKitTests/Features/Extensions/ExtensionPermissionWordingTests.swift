import RedentKit
import Testing

struct ExtensionPermissionWordingTests {
    @Test("Access to every site is said plainly, before anything else")
    func allSites() {
        let lines = ExtensionPermissionWording.lines(permissions: ["storage", "tabs"], hostPatterns: ["<all_urls>"])
        #expect(lines == ["Read and change all your data on all websites", "Read your browsing history"])
    }

    @Test("A few named sites are listed, the rest counted")
    func namedSites() {
        let patterns: Set = ["*://*.a.com/*", "https://b.com/*", "*://c.com/*", "*://d.com/*"]
        let lines = ExtensionPermissionWording.lines(permissions: [], hostPatterns: patterns)
        #expect(lines == ["Read and change your data on a.com, b.com, c.com and 1 more"])
    }

    @Test("Permissions with nothing to warn about add no line")
    func quietPermissions() {
        #expect(ExtensionPermissionWording.lines(permissions: ["storage", "alarms"], hostPatterns: []).isEmpty)
    }

    @Test("Chrome-only features get readable names, unknown ones keep theirs")
    func featureNames() {
        #expect(ExtensionPermissionWording.featureNames(["tabCapture", "fooBar"]) == ["fooBar", "Tab audio and video capture"])
    }
}
