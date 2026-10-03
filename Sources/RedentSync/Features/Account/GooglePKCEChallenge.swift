import CryptoKit
import Foundation
import RedentKit

public struct GooglePKCEChallenge: Sendable {
    public let verifier: String
    public let state: String
    public let authorizationURL: URL

    public init(configuration: SupabaseConfiguration) throws {
        var random = SystemRandomNumberGenerator()
        verifier = Self.encode(Data((0..<32).map { _ in UInt8.random(in: .min ... .max, using: &random) }))
        state = Self.encode(Data((0..<32).map { _ in UInt8.random(in: .min ... .max, using: &random) }))
        let challenge = Self.encode(Data(SHA256.hash(data: Data(verifier.utf8))))
        guard var components = URLComponents(
            url: configuration.supabaseURL.appendingPathComponent("auth/v1/authorize"),
            resolvingAgainstBaseURL: false
        ) else { throw AccountError.invalidConfiguration }
        var callback = URLComponents(url: configuration.callbackURL, resolvingAgainstBaseURL: false)
        callback?.queryItems = [URLQueryItem(name: "state", value: state)]
        guard let redirect = callback?.url else { throw AccountError.invalidConfiguration }
        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirect.absoluteString),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "s256")
        ]
        guard let url = components.url else { throw AccountError.invalidConfiguration }
        authorizationURL = url
    }

    public func code(from callback: URL, configuration: SupabaseConfiguration) throws -> String {
        guard callback.scheme == configuration.callbackURL.scheme,
              callback.host == configuration.callbackURL.host,
              Self.path(callback) == Self.path(configuration.callbackURL),
              callback.port == configuration.callbackURL.port,
              callback.user == nil, callback.password == nil,
              let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems
        else { throw AccountError.invalidCode }
        if items.contains(where: { $0.name == "error" }) { throw AccountError.invalidCode }
        let states = items.compactMap { $0.name == "state" ? $0.value : nil }
        guard states.count == 1, states[0] == state else { throw AccountError.invalidCode }
        let codes = items.compactMap { $0.name == "code" ? $0.value : nil }
        guard codes.count == 1, let code = codes.first, !code.isEmpty else { throw AccountError.invalidCode }
        return code
    }

    private static func path(_ url: URL) -> String {
        url.path.hasSuffix("/") && url.path.count > 1 ? String(url.path.dropLast()) : url.path
    }

    private static func encode(_ data: Data) -> String {
        data.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}
