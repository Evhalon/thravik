import Foundation
import RedentKit

extension WebTab {
    func blockOrganizationPolicy(for url: URL) {
        webView?.stopLoading()
        beginNavigation(to: url)
        pageTrustIssue = .organizationBlocked
    }
}
