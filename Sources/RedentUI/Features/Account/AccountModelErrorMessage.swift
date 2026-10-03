import RedentKit

enum AccountModelErrorMessage {
    static func message(for error: AccountError) -> String {
        switch error {
        case .invalidEmail: "Enter a valid email address."
        case .invalidCode: "That code is invalid or expired. Request a new code."
        case .invalidPassword: "Use a password with at least 8 characters."
        case .invalidCredentials: "That email and password did not match."
        case .unsupportedOperation: "This account option is unavailable."
        case .unauthorized: "Your account session expired. Sign in again."
        case .rateLimited: "Too many attempts. Wait a moment and try again."
        case .unavailable: "Account service is unavailable. Try again shortly."
        case .invalidConfiguration, .invalidResponse:
            "Account operation failed. Check your setup and try again."
        }
    }

    static func message(for error: VaultError) -> String {
        switch error {
        case .authenticationFailed: "Keychain access was denied. Unlock it and try again."
        case .keychain(let status): "Keychain operation failed (status \(status)). Try again."
        case .itemNotFound, .duplicateItem, .invalidData:
            "Secure account storage failed. Try again."
        }
    }
}
