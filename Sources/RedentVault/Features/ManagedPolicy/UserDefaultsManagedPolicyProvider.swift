import Foundation
import RedentKit

// @unchecked Sendable: UserDefaults is documented by Apple as thread-safe,
// but its Swift overlay doesn't declare Sendable conformance.
public struct UserDefaultsManagedPolicyProvider: ManagedPolicyProviding, @unchecked Sendable {
    public typealias ForcedValueChecker = @Sendable (String) -> Bool

    private let defaults: UserDefaults
    private let isForced: ForcedValueChecker

    public init(
        defaults: UserDefaults = .standard,
        isForced: @escaping ForcedValueChecker = { UserDefaults.standard.objectIsForced(forKey: $0) }
    ) {
        self.defaults = defaults
        self.isForced = isForced
    }

    public func current() -> ManagedPolicy {
        ManagedPolicy(
            homepageURL: forcedString(ManagedPolicyUserDefaultsKeys.homepageURL),
            defaultSearchEngine: forcedSearchEngine(),
            disablePrivateWindows: forcedBool(ManagedPolicyUserDefaultsKeys.disablePrivateWindows),
            disableExtensions: forcedBool(ManagedPolicyUserDefaultsKeys.disableExtensions),
            extensionAllowlist: forcedStringArray(ManagedPolicyUserDefaultsKeys.extensionAllowlist),
            disablePasswordSaving: forcedBool(ManagedPolicyUserDefaultsKeys.disablePasswordSaving),
            forceTrackerBlocking: forcedBool(ManagedPolicyUserDefaultsKeys.forceTrackerBlocking),
            disableAccountSync: forcedBool(ManagedPolicyUserDefaultsKeys.disableAccountSync),
            blockedURLPatterns: forcedStringArray(ManagedPolicyUserDefaultsKeys.urlBlocklist)
        )
    }

    private func forcedString(_ key: String) -> String? {
        guard isForced(key) else { return nil }
        return defaults.string(forKey: key)
    }

    private func forcedBool(_ key: String) -> Bool? {
        guard isForced(key) else { return nil }
        return defaults.object(forKey: key) as? Bool
    }

    private func forcedStringArray(_ key: String) -> [String]? {
        guard isForced(key) else { return nil }
        if let array = defaults.array(forKey: key) as? [String] { return array }
        if let single = defaults.string(forKey: key) {
            return single.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        return nil
    }

    private func forcedSearchEngine() -> ManagedDefaultSearchEngine? {
        guard isForced(ManagedPolicyUserDefaultsKeys.defaultSearchEngine),
              let raw = defaults.string(forKey: ManagedPolicyUserDefaultsKeys.defaultSearchEngine)
        else { return nil }
        return ManagedDefaultSearchEngine(forcedValue: raw)
    }
}
