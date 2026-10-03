import Foundation

public enum CustomSearchTemplate {
    public static let placeholder = "%s"

    public static func validated(_ template: String) -> Result<String, CustomSearchEngineError> {
        let trimmed = template.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.components(separatedBy: placeholder)
        guard parts.count == 2 else { return .failure(.missingQueryPlaceholder) }
        let probe = trimmed.replacingOccurrences(of: placeholder, with: "QUERY")
        guard let url = URL(string: probe),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host() != nil
        else { return .failure(.invalidTemplate) }
        return .success(trimmed)
    }

    public static func url(from template: String, query: String) -> URL? {
        guard case .success(let valid) = validated(template) else { return nil }
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+&=?#"))
        guard let escaped = query.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        return URL(string: valid.replacingOccurrences(of: placeholder, with: escaped))
    }
}
