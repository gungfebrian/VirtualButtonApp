import Combine
import CoreBluetooth
import Foundation

final class BLEManager: NSObject, ObservableObject {

    static let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    static let characteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")

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
            case .scanning:     return "Searching for ESP32-LED…"
            case .connecting:   return "Connecting…"
            case .connected:    return "Connected"
            case .disconnected: return "Disconnected"
            }
        }
    }

    @Published private(set) var state: ConnectionState = .disconnected
    @Published private(set) var isLedOn = false

    var isConnected: Bool { state == .connected }

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var ledCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Actions from the UI

    func setLed(on: Bool) {
        write(command: on ? 0x01 : 0x00)
    }

    func toggleLed() {
        write(command: 0x02)
    }

    func startScan() {
        guard central.state == .poweredOn else { return }
        state = .scanning
        central.scanForPeripherals(withServices: [Self.serviceUUID])
    }

    private func write(command: UInt8) {
        guard let peripheral, let characteristic = ledCharacteristic else { return }
        let type: CBCharacteristicWriteType =
            characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(Data([command]), for: characteristic, type: type)
    }

    private func cleanup() {
        peripheral = nil
        ledCharacteristic = nil
        isLedOn = false
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScan()
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
        central.stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        state = .connecting
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        state = .connected
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
        cleanup()
        state = .disconnected
        startScan()   // auto reconnect
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
