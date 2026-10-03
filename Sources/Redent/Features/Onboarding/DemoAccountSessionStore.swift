import RedentKit

actor DemoAccountSessionStore: AccountSessionStoring {
    private var session: AccountSession?

    func load() -> AccountSession? { session }
    func save(_ session: AccountSession) { self.session = session }
    func clear() { session = nil }
}
