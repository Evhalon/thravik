import Foundation
import Testing
@testable import RedentImport

struct ChromiumProfileLocatorTests {
    @Test("Uses profile names and order from Chromium Local State")
    func readsProfileIndex() throws {
        let root = try makeAppSupport()
        defer { try? FileManager.default.removeItem(at: root) }
        let dia = root.appending(path: "Dia/User Data")
        try writeProfile("Default", artifact: "History", in: dia)
        try writeProfile("Profile 12", artifact: "Bookmarks", in: dia)
        try writeLocalState(in: dia)

        let browsers = ChromiumProfileLocator.availableBrowsers(in: root)

        #expect(browsers.map(\.name) == ["Dia — Personal", "Dia — Work"])
        #expect(browsers.map(\.id) == ["Dia/User Data/Profile 12", "Dia/User Data/Default"])
    }

    @Test("Finds arbitrary profile folders with any importable data")
    func discoversUnindexedProfiles() throws {
        let root = try makeAppSupport()
        defer { try? FileManager.default.removeItem(at: root) }
        let arc = root.appending(path: "Arc/User Data")
        try writeProfile("Profile UUID", artifact: "Login Data", in: arc)
        try writeProfile("Cache", artifact: "unrelated", in: arc)

        let browsers = ChromiumProfileLocator.availableBrowsers(in: root)

        #expect(browsers.map(\.name) == ["Arc — Profile UUID"])
    }

    private func makeAppSupport() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "redent-profile-locator-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func writeProfile(_ name: String, artifact: String, in root: URL) throws {
        let profile = root.appending(path: name)
        try FileManager.default.createDirectory(at: profile, withIntermediateDirectories: true)
        try Data().write(to: profile.appending(path: artifact))
    }

    private func writeLocalState(in root: URL) throws {
        let json = """
        {"profile":{"profiles_order":["Profile 12","Default"],"info_cache":{
          "Default":{"name":"Work"},"Profile 12":{"name":"Personal"},
          "../escape":{"name":"Unsafe"}}}}
        """
        try Data(json.utf8).write(to: root.appending(path: "Local State"))
    }
}
