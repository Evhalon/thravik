import Foundation
import Observation
import RedentKit

/// Turns a site's two-factor setup page into a saved Authenticator account.
///
/// The page shows a QR code; one press reads it off the visible page, keeps
/// the seed in the Keychain, and links it to the site. From then on the
/// one-time-code button fills that site's codes — the setup's own confirmation
/// code first. No phone, no second app.
@MainActor @Observable
public final class TwoFactorSetupCoordinator {
    public enum Phase: Equatable, Sendable {
        case hidden
        case offered
        case reading
        case saved(accountName: String)
        case notFound
    }

    public typealias QRReader = @Sendable (Data) async throws -> [String]

    public private(set) var phase: Phase = .hidden
    private var origin: Origin?
    private let importer: any OTPAuthImporting
    private let store: any TOTPAccountStoring
    private let logger: any EventLogging
    private let readQRCodes: QRReader

    public init(
        importer: any OTPAuthImporting,
        store: any TOTPAccountStoring,
        logger: any EventLogging,
        readQRCodes: QRReader? = nil
    ) {
        self.importer = importer
        self.store = store
        self.logger = logger
        self.readQRCodes = readQRCodes ?? { try await QRImageDecoder.payloads(inImageData: $0) }
    }

    public var isVisible: Bool { phase != .hidden }

    public func setupAppeared(at origin: Origin) {
        self.origin = origin
        if phase == .hidden { phase = .offered }
    }

    /// A confirmation the user has not seen yet outlives the QR code leaving.
    public func setupGone() {
        guard phase == .offered || phase == .notFound else { return }
        phase = .hidden
    }

    public func pageChanged() {
        origin = nil
        phase = .hidden
    }

    public func dismiss() { phase = .hidden }

    /// Reads the setup QR code out of `pageImage` and saves its account.
    /// - Returns: the site the account now belongs to, or nil when the page
    ///   held no authenticator code.
    public func capture(pageImage: Data?) async -> Origin? {
        guard let origin, phase != .reading else { return nil }
        phase = .reading
        guard let pageImage, let account = await firstAccount(in: pageImage) else {
            phase = .notFound
            return nil
        }
        do {
            try await store.importAccounts([account])
            // Already in the vault from an earlier scan: link that copy instead.
            let stored = try await store.allAccounts().first { $0.secret == account.secret } ?? account
            try await store.link(stored.id, to: origin.registrableDomain)
            phase = .saved(accountName: stored.displayName)
            logger.notice("otp: two-factor setup saved for \(origin.registrableDomain)")
            return origin
        } catch {
            logger.error("otp: two-factor setup save failed — \(String(describing: error))")
            phase = .notFound
            return nil
        }
    }

    /// Only `otpauth://` codes count: any other QR on the page — a store
    /// link, an app download — is not an account and is never imported.
    private func firstAccount(in image: Data) async -> TOTPAccount? {
        guard let payloads = try? await readQRCodes(image) else { return nil }
        let importer = self.importer
        for payload in payloads where payload.lowercased().hasPrefix("otpauth://") {
            let decoded = try? await Task.detached(priority: .userInitiated) {
                try importer.accounts(fromScannedText: payload)
            }.value
            if let account = decoded?.first { return account }
        }
        return nil
    }
}
