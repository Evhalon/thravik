import Foundation
import RedentKit

struct SupabaseSessionResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: TimeInterval
    let user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }

    struct User: Decodable {
        let id: UUID
        let email: String?
        let appMetadata: AppMetadata?
        let identities: [Identity]?

        enum CodingKeys: String, CodingKey {
            case id, email, identities
            case appMetadata = "app_metadata"
        }

        var soleLoginMethod: AccountLoginMethod {
            let methods = Set((appMetadata?.providers ?? []) + (identities ?? []).map(\.provider))
                .compactMap(AccountLoginMethod.init(rawValue:))
            if methods.count == 1, let method = methods.first { return method }
            return .unknown
        }
    }

    struct AppMetadata: Decodable {
        let provider: String?
        let providers: [String]?
    }

    struct Identity: Decodable { let provider: String }
}
