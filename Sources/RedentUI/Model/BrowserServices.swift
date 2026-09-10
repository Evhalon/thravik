import RedentKit

public struct BrowserServices {
    public let history: any HistoryStoring
    public let bookmarks: any BookmarkStoring
    public let settings: any SettingsStoring
    public let session: any SessionStoring
    public let logger: any EventLogging
    /// Shared by every window: a download belongs to the app, not to whichever
    /// window happened to start it.
    public let downloads: DownloadsModel

    public init(history: any HistoryStoring, bookmarks: any BookmarkStoring,
                settings: any SettingsStoring, session: any SessionStoring,
                logger: any EventLogging, downloads: DownloadsModel) {
        self.history = history
        self.bookmarks = bookmarks
        self.settings = settings
        self.session = session
        self.logger = logger
        self.downloads = downloads
    }
}
