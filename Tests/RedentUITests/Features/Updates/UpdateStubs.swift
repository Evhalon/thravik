import Foundation
import RedentKit

/// Stand-ins for the update ports, so the model's state machine is testable
/// without a network or a disk image.
enum UpdateStubError: Error, LocalizedError {
    case offline
    case installRefused

    var errorDescription: String? {
        switch self {
        case .offline: "Could not reach the update server."
        case .installRefused: "/Applications is not writable."
        }
    }
}

struct StubChecker: UpdateChecking {
    let version: String

    func latestRelease() async throws -> AppRelease {
        guard let parsed = AppVersion(version),
              let url = URL(string: "https://example.invalid/Thravik-macOS.dmg")
        else { throw UpdateStubError.offline }
        return AppRelease(version: parsed, downloadURL: url)
    }
}

struct FailingChecker: UpdateChecking {
    func latestRelease() async throws -> AppRelease { throw UpdateStubError.offline }
}

struct StubInstaller: UpdateInstalling {
    func stage(_ release: AppRelease) async throws {}
}

struct FailingInstaller: UpdateInstalling {
    func stage(_ release: AppRelease) async throws { throw UpdateStubError.installRefused }
}
