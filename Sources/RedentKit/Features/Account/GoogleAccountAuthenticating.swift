import Foundation

public protocol GoogleAccountAuthenticating: Sendable {
    func authorizationURL() async throws -> URL
    func completeGoogleSignIn(callback: URL) async throws -> AccountSession
    func cancelGoogleSignIn() async
}
