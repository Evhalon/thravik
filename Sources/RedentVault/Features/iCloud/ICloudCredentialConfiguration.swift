import Foundation
import RedentKit

public struct ICloudCredentialConfiguration: Sendable {
    public let service: String
    public let accessGroup: String

    public init(service: String = "app.redent.browser.credentials", accessGroup: String) {
        self.service = service
        self.accessGroup = accessGroup
    }
}

public enum ICloudCredentialError: Error, Sendable, Equatable {
    case signingIdentityUnavailable
    case invalidAccessGroup
    case accessGroupUnavailable
    case invalidItem
}

struct ICloudCredentialRecord: Sendable {
    let account: String
    let password: Data
    let metadata: Data
}

protocol ICloudCredentialBackend: Sendable {
    func records() async throws -> [ICloudCredentialRecord]
    func upsert(_ record: ICloudCredentialRecord) async throws
    func updateMetadata(_ metadata: Data, account: String) async throws
    func delete(account: String) async throws
}
