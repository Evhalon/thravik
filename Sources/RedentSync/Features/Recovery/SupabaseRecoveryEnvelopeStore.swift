import Foundation
import RedentKit

public struct SupabaseRecoveryEnvelopeStore: RecoveryEnvelopeStoring {
    private let configuration: SupabaseConfiguration
    private let transport: any SupabaseHTTPTransport

    public init(configuration: SupabaseConfiguration,
                transport: any SupabaseHTTPTransport = URLSessionSupabaseTransport()) {
        self.configuration = configuration
        self.transport = transport
    }

    public func load(session: AccountSession) async throws -> SyncEncryptedEnvelope? {
        let data = try await send("vault_recovery_get", body: Data("{}".utf8), session: session)
        guard data != Data("null".utf8) else { return nil }
        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
              envelope.protocolVersion == 1, envelope.nonce.count == 12,
              envelope.ciphertext.count == 32, envelope.authenticationTag.count == 16 else {
            throw SyncError.invalidResponse
        }
        return envelope.value
    }

    public func saveIfAbsent(_ envelope: SyncEncryptedEnvelope, session: AccountSession) async throws -> Bool {
        let body = try JSONEncoder().encode(Request(envelope: Envelope(envelope)))
        let data = try await send("vault_recovery_create", body: body, session: session)
        guard let accepted = try? JSONDecoder().decode(Bool.self, from: data) else {
            throw SyncError.invalidResponse
        }
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

    private struct Request: Encodable { let envelope: Envelope }
    private struct Envelope: Codable {
        let protocolVersion: UInt16
        let nonce: Data
        let ciphertext: Data
        let authenticationTag: Data

        init(_ value: SyncEncryptedEnvelope) {
            protocolVersion = value.protocolVersion
            nonce = value.nonce
            ciphertext = value.ciphertext
            authenticationTag = value.authenticationTag
        }

        var value: SyncEncryptedEnvelope {
            SyncEncryptedEnvelope(protocolVersion: protocolVersion, nonce: nonce,
                                  ciphertext: ciphertext, authenticationTag: authenticationTag)
        }
    }
}
