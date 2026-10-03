import Foundation
import RedentKit

public struct URLSessionSupabaseTransport: SupabaseHTTPTransport {
    private let session: URLSession

    public init(session: URLSession? = nil) {
        if let session { self.session = session; return }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: configuration, delegate: SupabaseRedirectPolicy(), delegateQueue: nil)
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  response.url?.host == request.url?.host else { throw AccountError.invalidResponse }
            return (data, response)
        } catch is CancellationError { throw CancellationError() }
        catch let error as AccountError { throw error }
        catch { throw AccountError.unavailable }
    }
}
