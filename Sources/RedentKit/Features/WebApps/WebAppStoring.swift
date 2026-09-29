import Foundation

/// The sites the user keeps as apps, kept between launches.
public protocol WebAppStoring: Sendable {
    func all() async -> [WebApp]
    /// Inserts, or replaces the app with the same id.
    func save(_ app: WebApp) async
    func delete(_ id: UUID) async
}
