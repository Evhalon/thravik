import Foundation
import RedentKit

/// Maps the transport errors WebKit vends into the domain state the UI needs.
enum PageTrustIssueResolver {
    static func resolve(_ error: any Error) -> PageTrustIssue? {
        let error = error as NSError
        guard error.domain == NSURLErrorDomain else { return nil }
        let code = URLError.Code(rawValue: error.code)
        switch code {
        case .serverCertificateHasBadDate,
             .serverCertificateUntrusted,
             .serverCertificateHasUnknownRoot,
             .serverCertificateNotYetValid:
            return .invalidCertificate
        default:
            return nil
        }
    }
}
