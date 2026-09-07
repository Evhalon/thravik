import Foundation

public enum Base32Error: Error, Sendable, Equatable {
    case invalidCharacter(Character)
    case invalidLength
}

/// RFC 4648 base32 (alphabet `A–Z2–7`). Decoding is case-insensitive,
/// tolerates missing `=` padding, and ignores spaces and dashes — people
/// paste seeds formatted either way.
public enum Base32 {
    private static let alphabet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

    /// Character counts (mod 8, padding stripped) that map to a whole number
    /// of bytes. The others (1, 3, 6) would leave a fractional final byte.
    private static let validRemainders: Set<Int> = [0, 2, 4, 5, 7]

    public static func decode(_ string: String) throws -> Data {
        var symbols: [UInt8] = []
        symbols.reserveCapacity(string.count)
        for char in string {
            if char == "=" || char == " " || char == "-" { continue }
            guard let value = symbolValue(of: char) else {
                throw Base32Error.invalidCharacter(char)
            }
            symbols.append(value)
        }
        guard validRemainders.contains(symbols.count % 8) else {
            throw Base32Error.invalidLength
        }

        var bitBuffer: UInt64 = 0
        var bitCount = 0
        var bytes: [UInt8] = []
        bytes.reserveCapacity(symbols.count * 5 / 8)
        for value in symbols {
            bitBuffer = (bitBuffer << 5) | UInt64(value)
            bitCount += 5
            if bitCount >= 8 {
                bitCount -= 8
                bytes.append(UInt8((bitBuffer >> UInt64(bitCount)) & 0xFF))
            }
        }
        return Data(bytes)
    }

    public static func encode(_ data: Data, padded: Bool = false) -> String {
        guard !data.isEmpty else { return "" }
        var bitBuffer: UInt64 = 0
        var bitCount = 0
        var output = ""
        output.reserveCapacity((data.count * 8 + 4) / 5)
        for byte in data {
            bitBuffer = (bitBuffer << 8) | UInt64(byte)
            bitCount += 8
            while bitCount >= 5 {
                bitCount -= 5
                let index = Int((bitBuffer >> UInt64(bitCount)) & 0x1F)
                output.append(alphabet[index])
            }
        }
        if bitCount > 0 {
            let index = Int((bitBuffer << UInt64(5 - bitCount)) & 0x1F)
            output.append(alphabet[index])
        }
        if padded, output.count % 8 != 0 {
            output += String(repeating: "=", count: 8 - output.count % 8)
        }
        return output
    }

    /// ASCII-range lookup rather than `Character.uppercased()` — some
    /// Unicode characters expand to multiple code points when uppercased,
    /// which would break a single-character round trip.
    private static func symbolValue(of char: Character) -> UInt8? {
        guard let ascii = char.asciiValue else { return nil }
        switch ascii {
        case 65...90: return ascii - 65        // A-Z
        case 97...122: return ascii - 97       // a-z
        case 50...55: return ascii - 50 + 26   // 2-7
        default: return nil
        }
    }
}
