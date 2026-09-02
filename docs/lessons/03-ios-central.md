# Unit 3: the iPhone as a BLE central

## Learning goal

Trace the sequence Core Bluetooth follows from opening the app to sending an
LED command.

## Follow the connection

`BLEManager` is an `ObservableObject`. It owns the Core Bluetooth objects and
publishes simple state that SwiftUI can display. Keeping Bluetooth operations
in one object lets the view describe the interface without also managing the
radio lifecycle.

The connection sequence is:

```text
Bluetooth powers on
        |
        v
scan for the LED service
        |
        v
discover and select a board
        |
        v
connect -> discover service -> discover characteristic
        |
        v
read current state and enable notifications
```

Find each step in `VirtualButton/BLEManager.swift`:

| Step | Method or callback |
| --- | --- |
| Check radio state | `centralManagerDidUpdateState` |
| Scan | `startScan` |
| Receive an advertisement | `didDiscover` |
| Connect | `connect(to:)` and `didConnect` |
| Discover the service | `didDiscoverServices` |
| Discover the characteristic | `didDiscoverCharacteristicsFor` |
| Receive a value | `didUpdateValueFor` |

## Send a command

When a student taps ON, `ContentView` calls `setLed(on: true)`. The manager
converts that intent to byte `0x01` and writes it to the discovered
characteristic. The view never needs to know the UUID or Core Bluetooth write
type.

## Experiment

1. Power off the ESP32 and open the app.
2. Predict which connection state the interface will show.
3. Power on the ESP32 and watch the sequence change from scanning to connecting
   to connected.
4. Move the board out of range or reset it, then observe automatic
   reconnection.

Record each state you see and the physical event that caused it.

## Discuss

- Why does the app scan for one service UUID instead of every BLE device?
- Why is the last peripheral identifier saved in `UserDefaults`?
- Why does the app still need a device picker when boards share one protocol?

## Success check

You can put the scan, connect, service discovery, characteristic discovery,
read, and write operations in the correct order.
