import Foundation

struct EncryptedSyncMutation: Codable {
    let keyEpoch: UInt64
    let nonce: Data
    let ciphertext: Data
    let tag: Data
}
