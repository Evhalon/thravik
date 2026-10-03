import Foundation
import RedentKit

public actor UserDefaultsPasswordStoragePreference: PasswordStoragePreferenceStoring {
    private let defaults: UserDefaults
    private let key: String

    public init(suiteName: String, key: String = "password-storage-mode-v1") {
        defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.key = key
    }

    public func load() -> PasswordStorageMode {
        defaults.string(forKey: key).flatMap(PasswordStorageMode.init(rawValue:)) ?? .local
    }

    public func save(_ mode: PasswordStorageMode) { defaults.set(mode.rawValue, forKey: key) }
}
