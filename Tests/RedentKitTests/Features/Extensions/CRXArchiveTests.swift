import Foundation
import RedentKit
import Testing

struct CRXArchiveTests {
    private let zip: [UInt8] = [0x50, 0x4B, 0x03, 0x04, 0x0A, 0x00]

    private func littleEndian(_ value: UInt32) -> [UInt8] {
        (0..<4).map { UInt8(truncatingIfNeeded: value >> ($0 * 8)) }
    }

    @Test("A CRX3 header is skipped by its declared length")
    func crx3() throws {
        let header: [UInt8] = [1, 2, 3, 4, 5]
        let package = Array("Cr24".utf8) + littleEndian(3) + littleEndian(UInt32(header.count)) + header + zip
        #expect(try CRXArchive.zipPayload(of: Data(package)) == Data(zip))
    }

    @Test("A CRX2 header is skipped past its key and signature")
    func crx2() throws {
        let key: [UInt8] = [9, 9, 9]
        let signature: [UInt8] = [7, 7]
        let package = Array("Cr24".utf8) + littleEndian(2) + littleEndian(3) + littleEndian(2)
            + key + signature + zip
        #expect(try CRXArchive.zipPayload(of: Data(package)) == Data(zip))
    }

    @Test("A plain zip passes through untouched")
    func plainZip() throws {
        #expect(try CRXArchive.zipPayload(of: Data(zip)) == Data(zip))
    }

    @Test("Anything else is refused, and a header longer than the file is caught")
    func rejects() {
        #expect(throws: CRXArchive.Failure.notAnExtensionPackage) {
            try CRXArchive.zipPayload(of: Data("<html>".utf8))
        }
        let lying = Array("Cr24".utf8) + littleEndian(3) + littleEndian(999) + zip
        #expect(throws: CRXArchive.Failure.truncated) {
            try CRXArchive.zipPayload(of: Data(lying))
        }
        let future = Array("Cr24".utf8) + littleEndian(4) + littleEndian(0) + zip
        #expect(throws: CRXArchive.Failure.unsupportedVersion(4)) {
            try CRXArchive.zipPayload(of: Data(future))
        }
    }
}
