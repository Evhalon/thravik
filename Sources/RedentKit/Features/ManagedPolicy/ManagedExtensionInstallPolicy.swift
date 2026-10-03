import Foundation

public enum ManagedExtensionInstallPolicy {
    public static func allowsInstall(storeID: ChromeWebStoreID, policy: ManagedPolicy) -> Bool {
        let allowlist = normalizedAllowlist(policy.extensionAllowlist)
        if !allowlist.isEmpty {
            return allowlist.contains(storeID.rawValue.lowercased())
        }
        if policy.disableExtensions == true { return false }
        return true
    }

    public static func restrictsInstalls(_ policy: ManagedPolicy) -> Bool {
        policy.disableExtensions == true || !(policy.extensionAllowlist ?? []).isEmpty
    }

    private static func normalizedAllowlist(_ raw: [String]?) -> Set<String> {
        Set((raw ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty })
    }
}
