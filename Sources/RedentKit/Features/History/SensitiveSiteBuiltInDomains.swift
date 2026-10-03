import Foundation

/// Conservative built-in registrable domains when the banking/health toggle is on.
enum SensitiveSiteBuiltInDomains {
    static let bankingAndHealth: Set<String> = [
        "chase.com", "bankofamerica.com", "wellsfargo.com", "citi.com", "usbank.com",
        "capitalone.com", "americanexpress.com", "discover.com", "paypal.com", "venmo.com",
        "jpmorganchase.com", "pnc.com", "td.com", "regions.com", "ally.com",
        "kp.org", "mychart.com", "cigna.com", "anthem.com", "uhc.com"
    ]
}
