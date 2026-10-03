import Foundation
import RedentKit

public actor KeychainSyncDeviceStore: SyncDeviceKeyStoring {
    private let store: KeychainStore

    public init(service: String) { store = KeychainStore(service: service) }

    public func load(accountID: UUID) async throws -> SyncDeviceSecrets? {
        do {
            return try decode(try await store.fetch(account: accountID.uuidString).valueData)
        } catch VaultError.itemNotFound { return nil }
    }

    public func save(_ secrets: SyncDeviceSecrets, accountID: UUID) async throws {
        try await store.upsert(account: accountID.uuidString, label: "Redent sync device", valueData: try encode(secrets))
    }

    public func delete(accountID: UUID) async throws {
        try await store.delete(account: accountID.uuidString)
    }

    private func encode(_ secrets: SyncDeviceSecrets) throws -> Data {
        guard secrets.agreementPrivateKey.count == 32, secrets.signingPrivateKey.count == 32,
              secrets.credential.count == 32 else { throw VaultError.invalidData }
        return bytes(secrets.deviceID) + secrets.agreementPrivateKey + secrets.signingPrivateKey + secrets.credential
    }

    private func decode(_ data: Data) throws -> SyncDeviceSecrets {
        guard data.count == 112, let deviceID = uuid(data.prefix(16)) else { throw VaultError.invalidData }
        return SyncDeviceSecrets(deviceID: deviceID, agreementPrivateKey: Data(data[16..<48]),
                                 signingPrivateKey: Data(data[48..<80]), credential: Data(data[80..<112]))
    }

    private func bytes(_ id: UUID) -> Data {
        let u = id.uuid
        return Data([u.0, u.1, u.2, u.3, u.4, u.5, u.6, u.7, u.8, u.9, u.10, u.11, u.12, u.13, u.14, u.15])
    }

    private func uuid(_ data: Data.SubSequence) -> UUID? {
        let bytes = Array(data)
        guard bytes.count == 16 else { return nil }
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}
