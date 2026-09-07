import RedentKit

public struct BrowserServices {
    public let history: any HistoryStoring
    public let bookmarks: any BookmarkStoring
    public let settings: any SettingsStoring
    public let session: any SessionStoring
    public let logger: any EventLogging

    public init(history: any HistoryStoring, bookmarks: any BookmarkStoring,
                settings: any SettingsStoring, session: any SessionStoring, logger: any EventLogging) {
        self.history = history
        self.bookmarks = bookmarks
        self.settings = settings
        self.session = session
        self.logger = logger
    }
}
