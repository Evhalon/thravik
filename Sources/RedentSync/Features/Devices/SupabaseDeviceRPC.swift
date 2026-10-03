import Foundation
import RedentKit

struct SupabaseDeviceRPC {
    let configuration: SupabaseConfiguration
    let transport: any SupabaseHTTPTransport

    func call<Body: Encodable>(_ function: String, body: Body, session: AccountSession) async throws -> Data {
        var request = URLRequest(url: configuration.supabaseURL.appendingPathComponent("rest/v1/rpc/" + function))
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer " + session.accessToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let result: (Data, HTTPURLResponse)
        do { result = try await transport.send(request) }
        catch is CancellationError { throw CancellationError() }
        catch { throw SyncError.unavailable }
        guard result.0.count <= 1024 * 1024 else { throw SyncError.invalidResponse }
        if let error = SupabaseRPCFailure.error(data: result.0, status: result.1.statusCode) { throw error }
        switch result.1.statusCode {
        case 200..<300: return result.0
        case 401, 403: throw SyncError.unauthorized
        case 429: throw SyncError.rateLimited
        case 400: throw SyncError.invalidMutation
        default: throw SyncError.unavailable
        }
    }

}
