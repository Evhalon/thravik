import Foundation

/// Which registrable domains must not leave traces in history, timeline, form
/// history, or address-bar frecency.
public struct SensitiveSitePolicy: Sendable, Equatable {
    public var excludeBankingAndHealth: Bool
    public var customDomains: Set<String>

    public init(excludeBankingAndHealth: Bool = false, customDomains: Set<String> = []) {
        self.excludeBankingAndHealth = excludeBankingAndHealth
        self.customDomains = customDomains
    }

    public init(settings: BrowserSettings) {
        self.init(
            excludeBankingAndHealth: settings.excludeBankingAndHealthFromHistory,
            customDomains: Set(settings.sensitiveSiteHistoryDomains.map {
                Origin(scheme: "https", host: $0).registrableDomain
            })
        )
    }

    public func excludes(url: URL) -> Bool {
        guard let origin = Origin(url: url) else { return false }
        return excludes(origin: origin)
    }

    public func excludes(origin: Origin) -> Bool {
        excludes(registrableDomain: origin.registrableDomain)
    }

    public func excludes(registrableDomain domain: String) -> Bool {
        let normalized = domain.lowercased()
        if customDomains.contains(normalized) { return true }
        guard excludeBankingAndHealth else { return false }
        return SensitiveSiteBuiltInDomains.bankingAndHealth.contains(normalized)
    }
}
