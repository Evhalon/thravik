import Foundation
import RedentKit

/// Finds installed Chromium-family browsers and their profile folders by
/// probing well-known paths — never by enumerating the user's Library.
enum ChromiumProfileLocator {
    private struct Family {
        let name: String
        let relativePath: String
        let safeStorageService: String
    }

    private static let families: [Family] = [
        Family(name: "Comet", relativePath: "Comet", safeStorageService: "Comet Safe Storage"),
        Family(name: "Chrome", relativePath: "Google/Chrome", safeStorageService: "Chrome Safe Storage"),
        Family(name: "Brave", relativePath: "BraveSoftware/Brave-Browser", safeStorageService: "Brave Safe Storage"),
        Family(name: "Edge", relativePath: "Microsoft Edge", safeStorageService: "Microsoft Edge Safe Storage"),
        Family(name: "Vivaldi", relativePath: "Vivaldi", safeStorageService: "Vivaldi Safe Storage"),
        Family(name: "Arc", relativePath: "Arc/User Data", safeStorageService: "Arc Safe Storage"),
        Family(name: "Dia", relativePath: "Dia/User Data", safeStorageService: "Dia Safe Storage")
    ]

    static func availableBrowsers() -> [ImportableBrowser] {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard let appSupport else { return [] }

        return availableBrowsers(in: appSupport)
    }

    static func availableBrowsers(in appSupport: URL) -> [ImportableBrowser] {
        var browsers: [ImportableBrowser] = []
        for family in families {
            let familyRoot = appSupport.appending(path: family.relativePath)
            browsers.append(contentsOf: profiles(of: family, at: familyRoot))
        }
        return browsers
    }

    private static func profiles(of family: Family, at familyRoot: URL) -> [ImportableBrowser] {
        ChromiumProfileIndex.profiles(at: familyRoot).compactMap { profile in
            let folderName = profile.folderName
            let profileURL = familyRoot.appending(path: folderName)
            guard containsImportableData(profileURL) else { return nil }

            let label = profile.displayName ?? folderName
            return ImportableBrowser(
                id: "\(family.relativePath)/\(folderName)",
                name: "\(family.name) — \(label)",
                profileURL: profileURL,
                safeStorageService: family.safeStorageService
            )
        }
    }

    private static func containsImportableData(_ profileURL: URL) -> Bool {
        let fileNames = ["History", "Bookmarks", "Login Data", "Login Data For Account"]
        return fileNames.contains { fileName in
            FileManager.default.fileExists(atPath: profileURL.appending(path: fileName).path)
        }
    }
}
