# VirtualButton

VirtualButton is an iPhone controller for an ESP32 LED over Bluetooth Low
Energy (BLE). The physical button on the ESP32 and the ON/OFF controls in the
iPhone app update the same LED state.

This project uses Bluetooth only. It does not require Wi-Fi or internet access.

## Project layout

- `VirtualButton/` and `VirtualButton.xcodeproj/`: SwiftUI iPhone app.
- `esp32_ble_led/esp32_ble_led.ino`: ESP32 firmware.
- `tests/`: project configuration checks.

## Eight-board setup

All boards use the same service and characteristic UUIDs. Give each board a
different `DEVICE_NAME` before uploading its firmware:

| Board | Device name |
| --- | --- |
| 1 | `IOT101-1` |
| 2 | `IOT101-2` |
| 3 | `IOT101-3` |
| 4 | `IOT101-4` |
| 5 | `IOT101-5` |
| 6 | `IOT101-6` |
| 7 | `IOT101-7` |
| 8 | `IOT101-8` |

Keeping the UUIDs identical is intentional: they identify the VirtualButton
protocol. Each ESP32 still has a unique Bluetooth identity, and the app
remembers the specific board selected by the user.

The firmware is intended for one phone per ESP32 at a time. Label each physical
board with the same number used in `DEVICE_NAME` so users select the correct
board.

## ESP32 firmware

The sketch automatically selects these pin mappings:

| Target | LED | Physical button | Electrical behavior |
| --- | ---: | ---: | --- |
| ESP32-C3 | GPIO 8 | GPIO 9 / BOOT | Active-low |
| Classic ESP32 | GPIO 26 | GPIO 25 | Active-high LED, active-low button |

For an ESP32-C3 connected at `/dev/cu.usbmodem1101`:

```sh
arduino-cli compile --fqbn esp32:esp32:esp32c3 esp32_ble_led
arduino-cli upload -p /dev/cu.usbmodem1101 --fqbn esp32:esp32:esp32c3 esp32_ble_led
```

Change the port to the one shown by `arduino-cli board list`.

## iPhone app

1. Open `VirtualButton.xcodeproj` in Xcode.
2. Select your Apple development team in Signing & Capabilities.
3. Select a physical iPhone and run the app.
4. Allow Bluetooth access when iOS asks.
5. Tap the connection status at the bottom of the app, choose **Rescan**, then
   select the matching `IOT101-1` through `IOT101-8` board.

The boards normally do not appear in iOS **Settings > Bluetooth** because the
firmware does not use Bluetooth pairing. Discover and connect to them through
the picker inside VirtualButton. The iOS Simulator is not suitable for testing
the physical BLE connection.

## Verification

Run the Bluetooth permission regression test:

```sh
tests/test_bluetooth_permission.sh
```

The test builds the app and confirms that its generated `Info.plist` contains
the Bluetooth permission message required by iOS.
