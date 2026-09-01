# VirtualButton

VirtualButton is an educational Internet of Things project for learning how an
iPhone can control an ESP32 over Bluetooth Low Energy (BLE). Students build an
LED circuit, add a physical push button, upload the ESP32 firmware, and connect
to it from a SwiftUI app.

> This project uses Bluetooth only. It does not require Wi-Fi, an internet
> connection, a cloud account, or a server.

## Learning goals

By completing this project, students learn how to:

- control a GPIO output and protect an LED with a resistor;
- read an active-low push button with `INPUT_PULLUP`;
- debounce a mechanical button in software;
- create a BLE service and readable, writable, notifiable characteristic;
- scan, connect, write commands, and receive notifications with Core Bluetooth;
- keep the physical button and iPhone interface synchronized; and
- deploy the same BLE protocol to several uniquely named ESP32 boards.

## How it works

The ESP32 is a BLE peripheral and the iPhone is the BLE central. Both the
physical button and the app call the same LED-state logic.

```text
Physical button ─┐
                 ├─> ESP32 LED state ─> LED
iPhone app ─BLE──┘          └──────────> BLE notification to the app
```

The characteristic accepts one-byte commands:

| Value | Action |
| --- | --- |
| `0x00` or `"0"` | Turn the LED off |
| `0x01` or `"1"` | Turn the LED on |
| `0x02` or `"2"` | Toggle the LED |

## What you need

- one ESP32-WROOM development board or ESP32-C3 board;
- one LED;
- one 330 Ω resistor;
- one momentary push button;
- one breadboard and jumper wires;
- a data-capable USB cable;
- Arduino IDE or `arduino-cli` with the Espressif ESP32 core; and
- Xcode and a physical iPhone for the SwiftUI controller.

## Wiring: ESP32-WROOM

The following diagrams are for a classic ESP32-WROOM board. Disconnect USB
power while changing the circuit.

### Stage 1 — LED output

Connect GPIO 4 to the LED through a 330 Ω resistor, then connect the other LED
leg to GND. The resistor limits current and protects the LED and ESP32.

![ESP32-WROOM LED circuit using GPIO 4 and a 330 ohm resistor](docs/images/esp32-led-wiring.png)

| ESP32-WROOM pin | Connects to |
| --- | --- |
| GPIO 4 | 330 Ω resistor → LED anode |
| GND | LED cathode |

If the LED does not light, disconnect power and rotate the LED. LEDs work in
only one direction; the longer leg is normally the anode.

### Stage 2 — Add the physical push button

Keep the LED circuit from Stage 1, then connect the momentary button between
GPIO 25 and GND.

![ESP32-WROOM LED and push-button circuit using GPIO 4 and GPIO 25](docs/images/esp32-led-button-wiring.png)

| ESP32-WROOM pin | Connects to |
| --- | --- |
| GPIO 4 | 330 Ω resistor → LED anode |
| GPIO 25 | One side of the push button |
| GND | LED cathode and the other side of the push button |

The firmware configures GPIO 25 with `INPUT_PULLUP`. The input therefore reads
`HIGH` while released and `LOW` while pressed; no external pull-up resistor is
required.

## ESP32-C3 wiring

The diagrams above must not be copied pin-for-pin to an ESP32-C3 because that
board does not have GPIO 25. The firmware automatically uses the common onboard
controls instead:

| Target | LED | Physical button | LED polarity |
| --- | ---: | ---: | --- |
| ESP32-C3 | GPIO 8 | GPIO 9 / BOOT | Active-low |
| ESP32-WROOM | GPIO 4 | GPIO 25 | Active-high |

The mappings live in `esp32_ble_led/board_config.h` and are checked by an
automated test.

## Upload the ESP32 firmware

1. Open `esp32_ble_led/esp32_ble_led.ino` in Arduino IDE.
2. Select the correct ESP32 board and USB port.
3. Change `DEVICE_NAME` if this board needs a different classroom number.
4. Compile and upload the sketch.
5. Open Serial Monitor at 115200 baud.
6. Confirm that the board reports BLE advertising and its device name.

For an ESP32-C3 connected at `/dev/cu.usbmodem1101`:

```sh
arduino-cli compile --fqbn esp32:esp32:esp32c3 esp32_ble_led
arduino-cli upload -p /dev/cu.usbmodem1101 --fqbn esp32:esp32:esp32c3 esp32_ble_led
```

Use `arduino-cli board list` to find the correct port on another computer.

## Run the iPhone app

1. Open `VirtualButton.xcodeproj` in Xcode.
2. Select your Apple development team in **Signing & Capabilities**.
3. Select a physical iPhone and run the app.
4. Allow Bluetooth access when iOS asks.
5. Tap the connection status at the bottom of the app.
6. Tap **Rescan**, then select the correct `IOT101` board.
7. Test the ON/OFF controls and the physical push button.

The ESP32 normally does not appear in iOS **Settings > Bluetooth** because this
project does not use Bluetooth pairing. Discover and connect to it through the
picker inside VirtualButton. Use a physical iPhone; the iOS Simulator is not a
substitute for testing the BLE hardware connection.

## Classroom setup with eight boards

All boards intentionally use the same service and characteristic UUIDs. The
UUIDs identify the classroom protocol, while each ESP32 retains its own unique
Bluetooth identity.

Give every board a different `DEVICE_NAME` before uploading:

| Board label | Device name |
| --- | --- |
| 1 | `IOT101-1` |
| 2 | `IOT101-2` |
| 3 | `IOT101-3` |
| 4 | `IOT101-4` |
| 5 | `IOT101-5` |
| 6 | `IOT101-6` |
| 7 | `IOT101-7` |
| 8 | `IOT101-8` |

Label the physical boards with the same numbers. Each student should select one
board in the app; the firmware is intended for one phone per ESP32 at a time.
After the first connection, the app remembers that specific peripheral for
automatic reconnection.

## Suggested teaching sequence

1. **GPIO output:** assemble the first diagram and turn the LED on and off from
   firmware.
2. **BLE write:** send `0x00` and `0x01` from the iPhone app.
3. **Digital input:** add the push button and observe its active-low behavior.
4. **Debouncing:** compare raw button readings with the debounced result.
5. **Notifications:** press the physical button and watch the app update.
6. **Multiple peripherals:** name boards `IOT101-1` through `IOT101-8` and
   discuss why the protocol UUID can remain the same.

## Project layout

| Path | Purpose |
| --- | --- |
| `VirtualButton/` | SwiftUI and Core Bluetooth source code |
| `VirtualButton.xcodeproj/` | Xcode project |
| `esp32_ble_led/` | ESP32 firmware and board pin configuration |
| `docs/images/` | Breadboard wiring diagrams |
| `tests/` | Project and pin-configuration checks |

## Verification

Verify the documented board mappings:

```sh
tests/test_board_config.sh
```

Verify that the built iPhone app contains its required Bluetooth privacy
message:

```sh
tests/test_bluetooth_permission.sh
```

Compile the firmware for both supported board families:

```sh
arduino-cli compile --fqbn esp32:esp32:esp32c3 esp32_ble_led
arduino-cli compile --fqbn esp32:esp32:esp32 esp32_ble_led
```

## Safety and troubleshooting

- Use 3.3 V GPIO logic; never connect an ESP32 GPIO directly to 5 V.
- Always use the 330 Ω resistor in series with the LED.
- Disconnect USB power before moving jumper wires.
- If no board appears, confirm Bluetooth permission, board power, device name,
  and that another phone is not already connected.
- If the physical button does not respond, verify the board family and pin
  mapping before changing the software.
