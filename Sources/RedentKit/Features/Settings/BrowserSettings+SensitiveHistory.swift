import Foundation

extension BrowserSettings {
    /// Adds a registrable domain when valid and not already listed.
    public mutating func addSensitiveHistoryDomain(_ raw: String) -> Result<Void, SensitiveSiteDomainInputError> {
        switch SensitiveSiteDomainInput.registrableDomain(from: raw) {
        case .failure(let error):
            return .failure(error)
        case .success(let domain):
            guard !sensitiveSiteHistoryDomains.contains(where: { $0.caseInsensitiveCompare(domain) == .orderedSame })
            else { return .success(()) }
            sensitiveSiteHistoryDomains.append(domain)
            return .success(())
        }
    }
}
