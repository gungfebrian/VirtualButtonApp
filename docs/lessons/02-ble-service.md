# Unit 2: BLE services and characteristics

## Learning goal

Describe the roles of a BLE peripheral, service, and characteristic, and decode
the three commands used by VirtualButton.

## The project roles

The ESP32 is the **peripheral**. It advertises that it is available and hosts
the LED control data. The iPhone is the **central**. It scans for the service,
connects to one board, and exchanges data with it.

```text
iPhone central  -- scan and connect -->  ESP32 peripheral
iPhone central  -- write command ---->  LED characteristic
iPhone central  <-- state update -----  LED characteristic
```

A BLE **service** groups related behavior. A **characteristic** is a value
inside that service that clients can read, write, or observe. VirtualButton uses
one service and one characteristic so students can see the complete protocol
without framework code hiding it.

## Read the contract

The same UUID strings appear in `VirtualButton/BLEManager.swift` and
`esp32_ble_led/esp32_ble_led.ino`. They must match exactly:

| Item | UUID |
| --- | --- |
| LED service | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` |
| LED characteristic | `beb5483e-36e1-4688-b7f5-ea07361b26a8` |

The characteristic accepts a single byte:

| Byte | Meaning |
| ---: | --- |
| `0x00` | Turn the LED off |
| `0x01` | Turn the LED on |
| `0x02` | Toggle the current state |

The firmware also accepts the ASCII characters `"0"`, `"1"`, and `"2"` so
students can experiment with a generic BLE client as well as the iPhone app.

## Experiment

1. Find `SERVICE_UUID` in the ESP32 firmware.
2. Find `serviceUUID` in `BLEManager.swift`.
3. Change one character in the iPhone UUID, run the app, and observe that the
   board is no longer discovered.
4. Restore the UUID and confirm that the board appears again.

This controlled failure shows that a UUID is part of the protocol contract,
not a display name.

## Discuss

- Why can many classroom boards share a service UUID?
- Why is a one-byte command enough for a two-state LED?
- When would a project need more than one characteristic?

## Success check

You can label the iPhone and ESP32 roles, locate both UUID declarations, and
translate `0x00`, `0x01`, and `0x02` into LED actions.
