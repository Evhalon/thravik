import RedentKit
import SwiftUI

struct DeviceMembershipPane: View {
    @Bindable var model: DeviceMembershipModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Devices").font(.headline)
            localDevice
            pendingDevices
            if model.devices.contains(where: \.isLocal) == false {
                Button("Register This Mac") { Task { await model.refresh() } }
            }
            if model.isBusy { ProgressView() }
            if let message = model.message { Text(message).foregroundStyle(.red) }
        }
        .task { await model.refresh() }
    }

    @ViewBuilder
    private var localDevice: some View {
        if let local = model.devices.first(where: \.isLocal) {
            Text(local.fingerprint).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            Text(local.status == .approved ? "This Mac can sync." : "This Mac is waiting for approval.")
            if local.status == .pending { pendingLocal }
        }
    }

    private var pendingLocal: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Check Approval") { Task { await model.importKey() } }
            SecureField("Recovery code", text: $model.recoveryCode)
            Button("Authorize With Recovery Code") { Task { await model.claim() } }
                .disabled(model.recoveryCode.isEmpty)
        }
    }

    private var pendingDevices: some View {
        ForEach(model.devices.filter { !$0.isLocal && $0.status != .revoked }) { device in
            DeviceMembershipRow(device: device, approve: { Task { await model.approve(device.id) } },
                                revoke: { Task { await model.revoke(device.id) } })
        }
    }
}
