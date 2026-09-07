import Foundation

struct ChromiumProfileIndex {
    let folderName: String
    let displayName: String?

    static func profiles(at familyRoot: URL) -> [Self] {
        let localState = readLocalState(at: familyRoot)
        let discovered = discoveredFolders(at: familyRoot)
        let ordered = unique((localState?.profile.profilesOrder ?? []) + discovered)

        return ordered.compactMap { folderName in
            guard isSafeFolderName(folderName) else { return nil }
            let name = localState?.profile.infoCache[folderName]?.name
            return Self(folderName: folderName, displayName: normalized(name))
        }
    }

    private static func readLocalState(at root: URL) -> LocalState? {
        let url = root.appending(path: "Local State")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(LocalState.self, from: data)
    }

    private static func discoveredFolders(at root: URL) -> [String] {
        let keys: [URLResourceKey] = [.isDirectoryKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return urls.filter { url in
            (try? url.resourceValues(forKeys: Set(keys)).isDirectory) == true
        }.map(\.lastPathComponent).sorted()
    }

    private static func unique(_ names: [String]) -> [String] {
        var seen: Set<String> = []
        return names.filter { seen.insert($0).inserted }
    }

    private static func isSafeFolderName(_ name: String) -> Bool {
        !name.isEmpty && name != "." && name != ".." && !name.contains("/")
    }

    private static func normalized(_ name: String?) -> String? {
        guard let name else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private struct LocalState: Decodable {
        let profile: Profile

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            profile = try container.decodeIfPresent(Profile.self, forKey: .profile) ?? Profile()
        }

        private enum CodingKeys: String, CodingKey {
            case profile
        }
    }

    private struct Profile: Decodable {
        let infoCache: [String: Info]
        let profilesOrder: [String]

        init(infoCache: [String: Info] = [:], profilesOrder: [String] = []) {
            self.infoCache = infoCache
            self.profilesOrder = profilesOrder
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            infoCache = try container.decodeIfPresent([String: Info].self, forKey: .infoCache) ?? [:]
            profilesOrder = try container.decodeIfPresent([String].self, forKey: .profilesOrder) ?? []
        }

        enum CodingKeys: String, CodingKey {
            case infoCache = "info_cache"
            case profilesOrder = "profiles_order"
        }
    }

    private struct Info: Decodable {
        let name: String?
    }
}
