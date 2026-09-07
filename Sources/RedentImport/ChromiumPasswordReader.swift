import Foundation
import RedentKit

/// Chromium keeps local passwords in `Login Data` and account-synced ones in
/// `Login Data For Account`. Missing either file is normal; decrypting none
/// of a present file is not.
enum ChromiumPasswordReader {
    private static let files = ["Login Data", "Login Data For Account"]

    static func read(from profileURL: URL, key: [UInt8]) throws -> [Credential] {
        var combined: [Credential] = []
        var sawDatabase = false
        var failedDecrypts = 0

        for fileName in files {
            let source = profileURL.appending(path: fileName)
            guard FileManager.default.fileExists(atPath: source.path) else { continue }
            let copy = try TempDatabaseCopy(fileName: fileName, in: profileURL)
            sawDatabase = true
            defer { copy.cleanUp() }
            let batch = try LoginTableReader.read(from: copy.databaseURL, key: key)
            combined.append(contentsOf: batch.credentials)
            failedDecrypts += batch.failedDecrypts
        }

        guard sawDatabase else { throw ImportError.databaseUnreadable("Login Data") }
        if combined.isEmpty && failedDecrypts > 0 {
            throw ImportError.decryptionKeyUnavailable
        }
        return dedupe(combined)
    }

    private static func dedupe(_ credentials: [Credential]) -> [Credential] {
        var seen: Set<String> = []
        return credentials.filter { credential in
            let key = "\(credential.origin.scheme)|\(credential.origin.host)|\(credential.username)"
            return seen.insert(key).inserted
        }
    }
}
