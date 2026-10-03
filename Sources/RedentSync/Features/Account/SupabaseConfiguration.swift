import Foundation
import RedentKit

public struct SupabaseConfiguration: Sendable {
    public let supabaseURL: URL
    public let publishableKey: String
    public let callbackURL: URL

    public init(supabaseURL: URL, publishableKey: String, callbackURL: URL) throws {
        guard supabaseURL.scheme == "https", supabaseURL.host != nil,
              supabaseURL.user == nil, supabaseURL.password == nil,
              supabaseURL.query == nil, supabaseURL.fragment == nil,
              supabaseURL.path.isEmpty || supabaseURL.path == "/",
              publishableKey.hasPrefix("sb_publishable_"), publishableKey.count > 15, !publishableKey.contains(where: { $0.isWhitespace }),
              callbackURL.scheme == "redent" || callbackURL.scheme == "https",
              callbackURL.host != nil, callbackURL.user == nil, callbackURL.password == nil,
              callbackURL.query == nil,
              callbackURL.fragment == nil else { throw AccountError.invalidConfiguration }
        self.supabaseURL = supabaseURL
        self.publishableKey = publishableKey
        self.callbackURL = callbackURL
    }
}
