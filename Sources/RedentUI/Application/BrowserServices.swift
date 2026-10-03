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
    /// Shared with Settings so every window sees the same update state.
    public var updates: UpdateModel?
    /// Sites kept as apps. Nil where there is nowhere to keep them.
    public var webApps: (any WebAppStoring)?
    /// Gives each web app an app of its own in Applications. Nil in tests.
    public var webAppInstaller: (any WebAppInstalling)?
    /// Names automatic tab groups on the device. Nil keeps site names.
    public var groupNaming: (any TabGroupNaming)?
    /// Calendar events when the user turns meetings on. Nil in tests unless injected.
    public var calendar: (any CalendarEventsProviding)?

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
