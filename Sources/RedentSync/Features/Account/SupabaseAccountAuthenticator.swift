import Foundation
import RedentKit

public actor SupabaseAccountAuthenticator: AccountAuthenticating, GoogleAccountAuthenticating {
    private let configuration: SupabaseConfiguration
    private let transport: any SupabaseHTTPTransport
    private var googleChallenge: GooglePKCEChallenge?

    public init(configuration: SupabaseConfiguration,
                transport: any SupabaseHTTPTransport = URLSessionSupabaseTransport()) {
        self.configuration = configuration
        self.transport = transport
    }

    public func requestEmailCode(email: String) async throws {
        try validate(email: email)
        _ = try await send(path: "otp", body: ["email": email, "create_user": true])
    }

    public func verifyEmailCode(email: String, code: String) async throws -> AccountSession {
        try validate(email: email)
        guard (6...10).contains(code.count), code.allSatisfy({ $0.isASCII && $0.isNumber })
        else { throw AccountError.invalidCode }
        return try await session(path: "verify", body: ["email": email, "token": code, "type": "email"],
                                 loginMethod: .email)
    }

    public func signInWithPassword(email: String, password: String) async throws -> AccountSession {
        try validate(email: email)
        guard !password.isEmpty else { throw AccountError.invalidPassword }
        return try await session(path: "token?grant_type=password",
                                 body: ["email": email, "password": password],
                                 badRequest: .invalidCredentials, loginMethod: .email)
    }

    public func requestPasswordRecovery(email: String) async throws {
        try validate(email: email)
        _ = try await send(path: "recover", body: ["email": email], badRequest: .invalidEmail)
    }

    public func verifyPasswordRecoveryCode(email: String, code: String) async throws -> AccountSession {
        try validate(email: email)
        try validate(code: code)
        return try await session(path: "verify", body: ["email": email, "token": code, "type": "recovery"],
                                 loginMethod: .email)
    }

    public func updatePassword(session: AccountSession, password: String) async throws {
        try validate(password: password)
        guard validToken(session.accessToken) else { throw AccountError.unauthorized }
        let data = try await send(path: "user", body: ["password": password], token: session.accessToken,
                                  method: "PUT")
        guard let user = try? JSONDecoder().decode(SupabaseSessionResponse.User.self, from: data)
        else { throw AccountError.invalidResponse }
        guard user.id == session.accountID else { throw AccountError.unauthorized }
    }

    public func refresh(session: AccountSession) async throws -> AccountSession {
        guard validToken(session.refreshToken) else { throw AccountError.unauthorized }
        let refreshed = try await self.session(path: "token?grant_type=refresh_token",
                                               body: ["refresh_token": session.refreshToken],
                                               loginMethod: session.loginMethod)
        guard refreshed.accountID == session.accountID else { throw AccountError.unauthorized }
        return refreshed
    }

    public func signOut(session: AccountSession) async throws {
        _ = try await send(path: "logout?scope=local", body: [:], token: session.accessToken)
    }

    public func authorizationURL() async throws -> URL {
        let challenge = try GooglePKCEChallenge(configuration: configuration)
        googleChallenge = challenge
        return challenge.authorizationURL
    }

    public func completeGoogleSignIn(callback: URL) async throws -> AccountSession {
        guard let challenge = googleChallenge else { throw AccountError.invalidCode }
        googleChallenge = nil
        let code = try challenge.code(from: callback, configuration: configuration)
        return try await session(path: "token?grant_type=pkce",
                                 body: ["auth_code": code, "code_verifier": challenge.verifier],
                                 loginMethod: .google)
    }

    public func cancelGoogleSignIn() async { googleChallenge = nil }

    private func validToken(_ token: String) -> Bool {
        !token.isEmpty && token.utf8.allSatisfy { (33...126).contains($0) }
    }

    private func validate(email: String) throws {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard email.count <= 254, parts.count == 2, !parts[0].isEmpty,
              parts[1].contains("."), !email.contains(where: { $0.isWhitespace })
        else { throw AccountError.invalidEmail }
    }

    private func validate(password: String) throws {
        guard (8...128).contains(password.count), !password.contains(where: { $0.isNewline })
        else { throw AccountError.invalidPassword }
    }

    private func validate(code: String) throws {
        guard (6...10).contains(code.count), code.allSatisfy({ $0.isASCII && $0.isNumber })
        else { throw AccountError.invalidCode }
    }

    private func session(path: String, body: [String: Any],
                         badRequest: AccountError = .invalidCode,
                         loginMethod: AccountLoginMethod = .unknown) async throws -> AccountSession {
        let data = try await send(path: path, body: body, badRequest: badRequest)
        guard let response = try? JSONDecoder().decode(SupabaseSessionResponse.self, from: data),
              validToken(response.accessToken), validToken(response.refreshToken),
              response.expiresIn > 0 else { throw AccountError.invalidResponse }
        let method = loginMethod == .unknown ? response.user.soleLoginMethod : loginMethod
        return AccountSession(accountID: response.user.id, accessToken: response.accessToken,
                              refreshToken: response.refreshToken,
                              expiresAt: Date().addingTimeInterval(response.expiresIn),
                              identity: AccountIdentity(email: response.user.email, loginMethod: method))
    }

    private func send(path: String, body: [String: Any], token: String? = nil,
                      badRequest: AccountError = .invalidCode,
                      method: String = "POST") async throws -> Data {
        guard let url = URL(string: "auth/v1/" + path, relativeTo: configuration.supabaseURL)?.absoluteURL
        else { throw AccountError.invalidConfiguration }
        if let token, !validToken(token) { throw AccountError.unauthorized }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response): (Data, HTTPURLResponse)
        do { (data, response) = try await transport.send(request) }
        catch is CancellationError { throw CancellationError() }
        catch { throw AccountError.unavailable }
        switch response.statusCode {
        case 200..<300: return data
        case 401, 403: throw AccountError.unauthorized
        case 429: throw AccountError.rateLimited
        case 400, 422: throw badRequest
        default: throw AccountError.unavailable
        }
    }
}
