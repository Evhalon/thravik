import Foundation
import RedentKit

struct SyncDevicePageVerifier: Sendable {
    func verify(_ page: SyncPage, devices: [SyncDeviceRecord]) throws {
        for record in page.records {
            guard let signerID = record.signerDeviceID, let signature = record.signature,
                  let device = devices.first(where: { $0.id == signerID }), device.status != .pending,
                  SyncDeviceSigner().isValid(record.mutation, signature: signature, device: device)
            else { throw SyncError.deviceRejected }
        }
    }
}
