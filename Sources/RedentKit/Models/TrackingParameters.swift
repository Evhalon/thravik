import Foundation

/// Query parameters whose only job is to follow a click across sites.
///
/// Matched by exact name or by a campaign prefix — never by substring, so a
/// site's own `id` or `ref` survives. The list stays short on purpose: every
/// name here is one no page needs in order to render.
public enum TrackingParameters {
    private static let names: Set<String> = [
        "fbclid", "gclid", "dclid", "gbraid", "wbraid", "msclkid", "yclid",
        "twclid", "ttclid", "li_fat_id", "igshid", "mc_eid", "mc_cid",
        "_hsenc", "_hsmi", "__hssc", "__hstc", "__hsfp", "hsctatracking",
        "mkt_tok", "oly_anon_id", "oly_enc_id", "vero_id", "wickedid",
        "rb_clickid", "s_cid", "_openstat", "ml_subscriber", "ml_subscriber_hash",
        "epik", "ss_email_id", "bbeml", "sc_cid"
    ]
    private static let prefixes = ["utm_", "hsa_", "pk_campaign", "pk_kwd", "pk_source", "pk_medium"]

    /// The URL without its tracking parameters, or `nil` when it has none —
    /// so a caller can tell "nothing to do" from "rewrote it".
    public static func stripped(_ url: URL) -> URL? {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.percentEncodedQueryItems, !items.isEmpty
        else { return nil }
        let kept = items.filter { !isTracking($0.name) }
        guard kept.count != items.count else { return nil }
        // Percent-encoded items round-trip the rest of the query byte for byte;
        // decoding and re-encoding would rewrite values some servers compare.
        components.percentEncodedQueryItems = kept.isEmpty ? nil : kept
        return components.url
    }

    static func isTracking(_ name: String) -> Bool {
        let lowered = name.lowercased()
        return names.contains(lowered) || prefixes.contains { lowered.hasPrefix($0) }
    }
}
