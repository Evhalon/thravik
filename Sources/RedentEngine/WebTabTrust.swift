import Foundation
import RedentKit

extension WebTab {
    func acceptsInvalidCertificate(for protectionSpace: URLProtectionSpace) -> Bool {
        guard let key = invalidCertificateKey(host: protectionSpace.host) else { return false }
        return acceptedInvalidCertificateKeys.contains(key) || controller?.invalidCertificateAllowed?(key) == true
    }

    public func proceedThroughInvalidCertificate() {
        guard let url, let host = url.host(), let key = invalidCertificateKey(host: host) else { return }
        acceptedInvalidCertificateKeys.insert(key)
        controller?.trustInvalidCertificate?(key)
        load(url)
    }

    private func invalidCertificateKey(host: String) -> SiteKey? {
        guard !host.isEmpty else { return nil }
        let containerID = snapshot.containerID ?? BrowserContainer.defaultID
        return SiteKey(origin: Origin(scheme: "https", host: host), containerID: containerID)
    }
}
