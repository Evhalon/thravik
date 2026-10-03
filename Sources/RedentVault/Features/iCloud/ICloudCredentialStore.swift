import Foundation
import RedentKit
import Security

public actor ICloudCredentialStore: CredentialStoring {
    private let backend: any ICloudCredentialBackend
    private let configuration: ICloudCredentialConfiguration
    private let teamIdentifier: String?

    public init(configuration: ICloudCredentialConfiguration) {
        self.configuration = configuration
        backend = SecurityICloudCredentialBackend(configuration: configuration)
        teamIdentifier = KeychainCodeIdentity.teamIdentifier
    }

    public static func systemConfiguration(
        service: String = "app.redent.browser.credentials",
        bundleID: String
    ) throws -> ICloudCredentialConfiguration {
        guard let team = KeychainCodeIdentity.teamIdentifier else {
            throw ICloudCredentialError.signingIdentityUnavailable
        }
        let signedGroups = try signedAccessGroups()
        let configured = Bundle.main.object(forInfoDictionaryKey: "RedentICloudAccessGroup") as? String
        let candidate = configured ?? "\(team).\(bundleID)"
        guard candidate.hasPrefix(team + "."), signedGroups.contains(candidate) else {
            throw ICloudCredentialError.accessGroupUnavailable
        }
        return ICloudCredentialConfiguration(service: service, accessGroup: candidate)
    }

    init(configuration: ICloudCredentialConfiguration, backend: any ICloudCredentialBackend,
         teamIdentifier: String?) {
        self.configuration = configuration
        self.backend = backend
        self.teamIdentifier = teamIdentifier
    }

    public func credentials(for origin: Origin) async throws -> [Credential] {
        try await allCredentials().filter { $0.origin.matches(origin) }
    }

    public func allCredentials() async throws -> [Credential] {
        try validateIdentity()
        return try (await backend.records()).map(decode).sorted(by: ranked)
    }

    public func save(_ credential: Credential) async throws {
        try validateIdentity()
        let metadata = try JSONEncoder().encode(CredentialMetadata(credential: credential))
        let record = ICloudCredentialRecord(account: credential.id.uuidString,
            password: Data(credential.password.utf8), metadata: metadata)
        try await backend.upsert(record)
    }

    @discardableResult
    public func importCredentials(_ credentials: [Credential]) async throws -> [Credential] {
        let existing = try await allCredentials()
        let fresh = CredentialImportDeduper.newcomers(in: credentials, alreadyHave: existing)
        for credential in fresh { try await save(credential) }
        return fresh
    }

    public func markUsed(_ id: UUID) async throws {
        try validateIdentity()
        let account = id.uuidString
        guard let record = try await backend.records().first(where: { $0.account == account }) else {
            throw VaultError.itemNotFound
        }
        var metadata = try decodeMetadata(record.metadata)
        metadata.useCount += 1
        metadata.lastUsedAt = .now
        try await backend.updateMetadata(JSONEncoder().encode(metadata), account: account)
    }

    public func delete(_ id: UUID) async throws {
        try validateIdentity()
        try await backend.delete(account: id.uuidString)
    }

    private func validateIdentity() throws {
        guard let teamIdentifier, !teamIdentifier.isEmpty else {
            throw ICloudCredentialError.signingIdentityUnavailable
        }
        guard configuration.accessGroup.hasPrefix(teamIdentifier + ".") else {
            throw ICloudCredentialError.invalidAccessGroup
        }
    }

    private func decode(_ record: ICloudCredentialRecord) throws -> Credential {
        guard let id = UUID(uuidString: record.account),
              let password = String(data: record.password, encoding: .utf8) else {
            throw ICloudCredentialError.invalidItem
        }
        return try decodeMetadata(record.metadata).credential(id: id, password: password)
    }

    private func decodeMetadata(_ data: Data) throws -> CredentialMetadata {
        guard let value = try? JSONDecoder().decode(CredentialMetadata.self, from: data) else {
            throw ICloudCredentialError.invalidItem
        }
        return value
    }

    private func ranked(_ left: Credential, _ right: Credential) -> Bool {
        if left.useCount != right.useCount { return left.useCount > right.useCount }
        return (left.lastUsedAt ?? .distantPast) > (right.lastUsedAt ?? .distantPast)
    }

    private static func signedAccessGroups() throws -> [String] {
        var code: SecCode?
        guard SecCodeCopySelf(SecCSFlags(), &code) == errSecSuccess, let code else {
            throw ICloudCredentialError.signingIdentityUnavailable
        }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, SecCSFlags(), &staticCode) == errSecSuccess,
              let staticCode else { throw ICloudCredentialError.signingIdentityUnavailable }
        var information: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
        guard SecCodeCopySigningInformation(staticCode, flags, &information) == errSecSuccess,
              let information,
              let dictionary = (information as NSDictionary)[kSecCodeInfoEntitlementsDict] as? [String: Any],
              let groups = dictionary["keychain-access-groups"] as? [String] else {
            throw ICloudCredentialError.accessGroupUnavailable
        }
        return groups
    }
}
