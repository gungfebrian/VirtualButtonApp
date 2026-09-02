# Unit 7: identity in a multi-board classroom

## Learning goal

Distinguish a shared BLE protocol from the names and identifiers that represent
individual physical boards.

## Shared behavior, separate identity

All eight classroom boards use the same service UUID and characteristic UUID.
That shared contract tells the app, "this device speaks the VirtualButton
protocol." It does not mean the boards are the same peripheral.

Each board has two useful forms of identity:

| Identity | Example | Purpose |
| --- | --- | --- |
| Advertised name | `IOT101-3` | A label that students can recognize |
| Peripheral identifier | An iOS-managed UUID | A stable key the app can remember |

The device picker displays the advertised name and signal strength. After a
student connects, the app saves the selected peripheral identifier so it can
reconnect to that specific board on the next launch.

## Prepare eight boards

Before uploading, set `DEVICE_NAME` in `esp32_ble_led/esp32_ble_led.ino` to
match the physical label:

| Board | Firmware name |
| ---: | --- |
| 1 | `IOT101-1` |
| 2 | `IOT101-2` |
| 3 | `IOT101-3` |
| 4 | `IOT101-4` |
| 5 | `IOT101-5` |
| 6 | `IOT101-6` |
| 7 | `IOT101-7` |
| 8 | `IOT101-8` |

Keep the protocol UUIDs unchanged. Label each board with the same number shown
in its advertised name.

## Classroom experiment

1. Power two or more uniquely named boards.
2. Open the device picker and compare their names and RSSI values.
3. Move one board farther from the phone and rescan.
4. Connect to one board, close the app, and open it again.
5. Observe which identity is useful for display and which is useful for
   automatic reconnection.

RSSI is an approximate signal-strength observation, not a precise distance
measurement. Bodies, furniture, radio interference, and antenna orientation
all affect it.

## Discuss

- Why should the class not create a different service UUID for every board?
- Why is a human-readable name insufficient as a database key?
- What happens if two teams accidentally upload the same advertised name?

## Success check

You can explain why eight boards share protocol UUIDs while retaining separate
names and peripheral identifiers.
