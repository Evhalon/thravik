import RedentKit

actor RouterPreferenceStore: PasswordStoragePreferenceStoring {
    private var mode: PasswordStorageMode
    private var saveFailure = false

    init(_ mode: PasswordStorageMode = .local) { self.mode = mode }
    func failSaves() { saveFailure = true }
    func load() -> PasswordStorageMode { mode }
    func save(_ mode: PasswordStorageMode) throws {
        guard !saveFailure else { throw PasswordStorageError.unavailable }
        self.mode = mode
    }
}
