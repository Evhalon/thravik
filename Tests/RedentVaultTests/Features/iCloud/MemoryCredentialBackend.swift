import Foundation
import RedentKit
@testable import RedentVault

actor MemoryCredentialBackend: ICloudCredentialBackend {
    private var values: [String: ICloudCredentialRecord] = [:]

    func records() async throws -> [ICloudCredentialRecord] { Array(values.values) }

    func upsert(_ record: ICloudCredentialRecord) async throws {
        values[record.account] = record
    }

    func updateMetadata(_ metadata: Data, account: String) async throws {
        guard let current = values[account] else { throw VaultError.itemNotFound }
        values[account] = ICloudCredentialRecord(account: account,
            password: current.password, metadata: metadata)
    }

    func delete(account: String) async throws {
        guard values.removeValue(forKey: account) != nil else { throw VaultError.itemNotFound }
    }

    func insert(_ record: ICloudCredentialRecord) { values[record.account] = record }
    func count() -> Int { values.count }
}
