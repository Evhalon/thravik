import RedentKit
import SwiftUI

struct DeviceMembershipRow: View {
    let device: SyncDeviceSummary
    let approve: () -> Void
    let revoke: () -> Void

    var body: some View {
        HStack {
            Text(device.fingerprint).font(.system(.caption2, design: .monospaced))
            Spacer()
            if device.status == .pending { Button("Approve", action: approve) }
            if device.status == .approved { Button("Revoke", action: revoke) }
        }
    }
}
