import Foundation
import RedentKit

public struct SupabasePasswordEnvelopeStore: PasswordEnvelopeStoring {
    private let configuration: SupabaseConfiguration
    private let transport: any SupabaseHTTPTransport

    public init(configuration: SupabaseConfiguration,
                transport: any SupabaseHTTPTransport = URLSessionSupabaseTransport()) {
        self.configuration = configuration
        self.transport = transport
    }

    public func load(session: AccountSession) async throws -> PasswordKeyEnvelope? {
        let data = try await send("vault_password_get", body: Data("{}".utf8), session: session)
        guard data != Data("null".utf8) else { return nil }
        guard let envelope = try? JSONDecoder().decode(PasswordKeyEnvelope.self, from: data) else {
            throw SyncError.invalidResponse
        }
        try Self.validate(envelope)
        return envelope
    }

    public func saveIfAbsent(_ envelope: PasswordKeyEnvelope, session: AccountSession) async throws -> Bool {
        try Self.validate(envelope)
        let data = try JSONEncoder().encode(Request(envelope: envelope))
        let response = try await send("vault_password_create", body: data, session: session)
        guard let accepted = try? JSONDecoder().decode(Bool.self, from: response) else {
            throw SyncError.invalidResponse
        }
        return accepted
    }

    public func replace(_ envelope: PasswordKeyEnvelope, expected: PasswordKeyEnvelope,
                        claimKey: Data, session: AccountSession) async throws -> Bool {
        try Self.validate(envelope)
        try Self.validate(expected)
        guard claimKey.count == 32 else { throw SyncError.invalidResponse }
        let body = try JSONEncoder().encode(Replacement(envelope: envelope, expected: expected,
                                                       claim_key: claimKey.base64EncodedString()))
        let data = try await send("vault_password_replace", body: body, session: session)
        guard let accepted = try? JSONDecoder().decode(Bool.self, from: data) else { throw SyncError.invalidResponse }
        return accepted
    }

    private func send(_ function: String, body: Data, session: AccountSession) async throws -> Data {
        var request = URLRequest(url: configuration.supabaseURL.appendingPathComponent("rest/v1/rpc/" + function))
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer " + session.accessToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let result: (Data, HTTPURLResponse)
        do { result = try await transport.send(request) }
        catch is CancellationError { throw CancellationError() }
        catch { throw SyncError.unavailable }
        guard result.0.count < 4096 else { throw SyncError.invalidResponse }
        if let error = SupabaseRPCFailure.error(data: result.0, status: result.1.statusCode) { throw error }
        switch result.1.statusCode {
        case 200..<300: return result.0
        case 401, 403: throw SyncError.unauthorized
        case 429: throw SyncError.rateLimited
        default: throw SyncError.unavailable
        }
    }

    private static func validate(_ envelope: PasswordKeyEnvelope) throws {
        guard envelope.protocolVersion == 1, envelope.kdf == "pbkdf2-hmac-sha256",
              envelope.iterations == 600_000, envelope.salt.count == 32, envelope.nonce.count == 12,
              envelope.ciphertext.count == 73, envelope.authenticationTag.count == 16 else {
            throw SyncError.invalidResponse
        }
    }

    private struct Request: Encodable { let envelope: PasswordKeyEnvelope }
    private struct Replacement: Encodable {
        let envelope: PasswordKeyEnvelope
        let expected: PasswordKeyEnvelope
        let claim_key: String
    }
}
