import Foundation
import Security
import RedentKit

/// Low-level Keychain primitives shared by the credential and TOTP stores.
///
/// Every method blocks on a Security.framework syscall. Funneling them
/// through an actor keeps that blocking work off the caller's executor
/// (never the main actor) without introducing shared mutable state.
actor KeychainStore {
    struct Item {
        let account: String
        let valueData: Data
        let genericData: Data?
    }

    private let access: KeychainItemAccess
    private var itemCache: [String: Item] = [:]

    init(service: String) {
        access = KeychainItemAccess(service: service)
    }

    /// Data-protection keychain only, unless `allowingInteraction` is set so a
    /// one-time ACL unlock can migrate leftovers after a signing-identity change.
    func fetchAll(allowingInteraction: Bool = false) -> [Item] {
        let items = KeychainSecretReader.allReadable(
            service: access.service, allowingInteraction: allowingInteraction
        )
        for item in items { itemCache[item.account] = item }
        return items
    }

    func fetch(account: String, allowingInteraction: Bool = false) throws -> Item {
        if !allowingInteraction, let hit = itemCache[account] { return hit }
        let item = try access.fetch(account: account, allowingInteraction: allowingInteraction)
        itemCache[account] = item
        return item
    }

    /// Silent first. One interactive unlock rewrites the item so its ACL
    /// matches this binary's designated requirement, not a stale cdhash.
    func loadOrUnlock(account: String, label: String) throws -> Item {
        do {
            return try fetch(account: account, allowingInteraction: false)
        } catch VaultError.authenticationFailed {
            let item = try fetch(account: account, allowingInteraction: true)
            rebind(account: account, label: label, valueData: item.valueData)
            return item
        }
    }

    private func rebind(account: String, label: String, valueData: Data) {
        do {
            try access.delete(account: account)
            try access.add(account: account, label: label, valueData: valueData, genericData: nil)
            itemCache[account] = Item(account: account, valueData: valueData, genericData: nil)
        } catch {}
    }

    func exists(account: String) -> Bool {
        access.exists(account: account)
    }

    func add(account: String, label: String, valueData: Data, genericData: Data? = nil) throws {
        itemCache.removeValue(forKey: account)
        try access.add(account: account, label: label, valueData: valueData, genericData: genericData)
        itemCache[account] = Item(account: account, valueData: valueData, genericData: genericData)
    }

    func upsert(account: String, label: String, valueData: Data) throws {
        itemCache.removeValue(forKey: account)
        do {
            try access.update(account: account, label: label, valueData: valueData, genericData: nil)
        } catch VaultError.itemNotFound {
            try access.add(account: account, label: label, valueData: valueData, genericData: nil)
        }
        itemCache[account] = Item(account: account, valueData: valueData, genericData: nil)
    }

    func update(account: String, label: String?, valueData: Data?, genericData: Data?) throws {
        itemCache.removeValue(forKey: account)
        try access.update(account: account, label: label, valueData: valueData, genericData: genericData)
    }

    func delete(account: String) throws {
        itemCache.removeValue(forKey: account)
        try access.delete(account: account)
    }

    static func item(from dict: [String: Any]) throws -> Item {
        guard let account = KeychainAttributeCodec.account(from: dict),
              let valueData = KeychainAttributeCodec.valueData(from: dict)
        else { throw VaultError.invalidData }
        return Item(account: account, valueData: valueData, genericData: KeychainAttributeCodec.genericData(from: dict))
    }
}
