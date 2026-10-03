import Foundation
import RedentKit

struct CloudCredentialPayload: Codable {
    let id: UUID
    let origin: Origin
    let username: String
    let password: String
    let spaceID: UUID?
    let createdAt: Date
    let lastUsedAt: Date?
    let useCount: Int

    init(_ credential: Credential) {
        id = credential.id
        origin = credential.origin
        username = credential.username
        password = credential.password
        spaceID = credential.spaceID
        createdAt = credential.createdAt
        lastUsedAt = credential.lastUsedAt
        useCount = credential.useCount
    }

    var credential: Credential {
        Credential(id: id, origin: origin, username: username, password: password,
                   spaceID: spaceID, createdAt: createdAt, lastUsedAt: lastUsedAt, useCount: useCount)
    }
}
