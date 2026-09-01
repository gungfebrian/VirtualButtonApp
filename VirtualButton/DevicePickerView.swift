import SwiftUI

/// A BLE peripheral never appears in iOS Settings > Bluetooth unless it bonds,
/// so the app provides its own picker. This is the standard Core Bluetooth
/// pattern: scan, list what was found, and let the user tap one.
struct DevicePickerView: View {
    @ObservedObject var ble: BLEManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if ble.devices.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Looking for nearby boards…")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    } else {
                        ForEach(ble.devices) { device in
                            Button {
                                ble.connect(to: device)
                                dismiss()
                            } label: {
                                deviceRow(device)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Devices")
                } footer: {
                    Text("Only boards advertising the LED service are listed. "
                         + "Make sure the ESP32 is powered and not already connected to another phone.")
                }

                if ble.isConnected {
                    Section {
                        Button("Disconnect", role: .destructive) {
                            ble.disconnect()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Connect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Rescan") { ble.startScan() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onDisappear { ble.stopScan() }
        }
        .presentationDetents([.medium, .large])
    }

    private func deviceRow(_ device: BLEManager.Device) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.body.weight(.medium))
                Text("\(device.rssi) dBm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if ble.connectedName == device.name && ble.isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: signalIcon(for: device.rssi))
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }

    // RSSI is negative; closer to zero means a stronger signal.
    private func signalIcon(for rssi: Int) -> String {
        switch rssi {
        case (-60)...:     return "cellularbars"
        case (-75)..<(-60): return "wifi.medium"
        default:            return "wifi.slash"
        }
    }
}
