import Combine
import CoreBluetooth
import Foundation

/// Handles everything BLE: scanning, connecting, writing commands, and listening
/// for notifications from the ESP32 (so the UI stays in sync when the LED is
/// toggled by the physical button).
///
/// Connection is manual: the app scans and publishes every nearby board in
/// `devices`, and the user picks one. The chosen device is remembered so the
/// next launch reconnects to it straight away.
final class BLEManager: NSObject, ObservableObject {

    // Must match the UUIDs in the ESP32 sketch exactly
    static let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    static let characteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")

    private static let lastDeviceKey = "lastConnectedPeripheralID"

    /// One board found during a scan, as shown in the picker.
    struct Device: Identifiable, Equatable {
        let id: UUID        // CBPeripheral.identifier
        var name: String
        var rssi: Int
    }

    enum ConnectionState: Equatable {
        case poweredOff
        case unauthorized
        case scanning
        case connecting
        case connected
        case disconnected

        var label: String {
            switch self {
            case .poweredOff:   return "Bluetooth is off"
            case .unauthorized: return "Bluetooth permission denied"
            case .scanning:     return "Scanning…"
            case .connecting:   return "Connecting…"
            case .connected:    return "Connected"
            case .disconnected: return "Not connected"
            }
        }
    }

    @Published private(set) var state: ConnectionState = .disconnected
    @Published private(set) var isLedOn = false
    @Published private(set) var devices: [Device] = []
    @Published private(set) var connectedName: String?

    var isConnected: Bool { state == .connected }
    var isScanning: Bool { state == .scanning }

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var ledCharacteristic: CBCharacteristic?
    private var discovered: [UUID: CBPeripheral] = [:]
    private var pendingName: String?
    private var userInitiatedDisconnect = false

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - LED commands

    func setLed(on: Bool) {
        write(command: on ? 0x01 : 0x00)
    }

    func toggleLed() {
        write(command: 0x02)
    }

    private func write(command: UInt8) {
        guard let peripheral, let characteristic = ledCharacteristic else { return }
        let type: CBCharacteristicWriteType =
            characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(Data([command]), for: characteristic, type: type)
    }

    // MARK: - Manual connection control

    /// Apple recommends always passing a service UUID rather than nil, so the
    /// picker only ever lists boards running our sketch.
    func startScan() {
        guard central.state == .poweredOn, !isConnected else { return }
        devices.removeAll()
        discovered.removeAll()
        state = .scanning
        central.scanForPeripherals(withServices: [Self.serviceUUID])
    }

    func stopScan() {
        central.stopScan()
        if state == .scanning { state = .disconnected }
    }

    func connect(to device: Device) {
        guard let target = discovered[device.id] else { return }
        central.stopScan()
        userInitiatedDisconnect = false
        pendingName = device.name
        peripheral = target
        target.delegate = self
        state = .connecting
        central.connect(target)
    }

    /// Disconnects and forgets the board, so the next launch shows the picker.
    func disconnect() {
        userInitiatedDisconnect = true
        UserDefaults.standard.removeObject(forKey: Self.lastDeviceKey)
        if let peripheral {
            central.cancelPeripheralConnection(peripheral)
        } else {
            cleanup()
            state = .disconnected
        }
    }

    /// Reconnect to the board chosen last time, without making the user pick again.
    private func reconnectSavedDeviceOrScan() {
        guard
            let saved = UserDefaults.standard.string(forKey: Self.lastDeviceKey),
            let uuid = UUID(uuidString: saved),
            let known = central.retrievePeripherals(withIdentifiers: [uuid]).first
        else {
            startScan()
            return
        }

        pendingName = known.name
        peripheral = known
        known.delegate = self
        state = .connecting
        central.connect(known)   // no timeout: connects whenever the board shows up
    }

    private func cleanup() {
        peripheral = nil
        ledCharacteristic = nil
        connectedName = nil
        isLedOn = false
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            reconnectSavedDeviceOrScan()
        case .unauthorized:
            state = .unauthorized
        default:
            cleanup()
            state = .poweredOff
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        // The advertised local name is always fresh; peripheral.name can be a
        // stale GAP name cached by iOS from an earlier connection.
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? peripheral.name
            ?? "Unnamed device"

        discovered[peripheral.identifier] = peripheral

        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            devices[index].name = name
            devices[index].rssi = RSSI.intValue
        } else {
            devices.append(Device(id: peripheral.identifier, name: name, rssi: RSSI.intValue))
        }
        devices.sort { $0.rssi > $1.rssi }   // strongest signal first
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        state = .connected
        connectedName = peripheral.name ?? pendingName
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: Self.lastDeviceKey)
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        cleanup()
        startScan()
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        let wasManual = userInitiatedDisconnect
        userInitiatedDisconnect = false
        isLedOn = false
        ledCharacteristic = nil
        connectedName = nil

        if wasManual {
            self.peripheral = nil
            state = .disconnected
            startScan()
        } else {
            // Dropped out of range or the board rebooted: keep the pending
            // connection open, it completes as soon as the board is back.
            state = .connecting
            central.connect(peripheral)
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID })
        else { return }
        peripheral.discoverCharacteristics([Self.characteristicUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristic = service.characteristics?
            .first(where: { $0.uuid == Self.characteristicUUID }) else { return }

        ledCharacteristic = characteristic
        // Read the current state, then subscribe so physical button presses show up here
        peripheral.readValue(for: characteristic)
        peripheral.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard let byte = characteristic.value?.first else { return }
        isLedOn = (byte == 0x01 || byte == UInt8(ascii: "1"))
    }
}
