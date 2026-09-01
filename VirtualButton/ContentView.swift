import SwiftUI

struct ContentView: View {
    @StateObject private var ble = BLEManager()
    @State private var showingPicker = false

    var body: some View {
        VStack(spacing: 14) {
            powerButton(turnOn: true)
            powerButton(turnOn: false)
            connectionBar
        }
        .padding(16)
        .sheet(isPresented: $showingPicker) {
            DevicePickerView(ble: ble)
        }
    }

    // Each button fills half of the available height.
    // The one matching the current LED state stays fully saturated;
    // the other dims, so the LED state is readable at a glance.
    private func powerButton(turnOn: Bool) -> some View {
        let isActive = (ble.isLedOn == turnOn)
        let tint: Color = turnOn ? .green : .red

        return Button {
            ble.setLed(on: turnOn)
        } label: {
            VStack(spacing: 16) {
                Image(systemName: turnOn ? "power" : "power.dotted")
                    .font(.system(size: 80, weight: .bold))
                Text(turnOn ? "ON" : "OFF")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tint.opacity(isActive ? 1 : 0.28))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(isActive ? 0.9 : 0), lineWidth: 4)
            )
            .shadow(color: isActive ? tint.opacity(0.5) : .clear, radius: 20, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!ble.isConnected)
        .opacity(ble.isConnected ? 1 : 0.5)
        .animation(.easeInOut(duration: 0.18), value: ble.isLedOn)
    }

    /// Tapping the status line opens the device picker.
    private var connectionBar: some View {
        Button {
            if !ble.isConnected { ble.startScan() }
            showingPicker = true
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(ble.isConnected ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                Text(ble.connectedName ?? ble.state.label)
                    .font(.footnote)
                Image(systemName: "chevron.up")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Gives the big buttons a tactile press response.
private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
