import Foundation
import RedentKit

public protocol SupabaseHTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
