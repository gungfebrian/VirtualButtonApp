# Unit 6: notifications and synchronized state

## Learning goal

Explain why BLE notifications are needed when both the iPhone and the physical
button can change the same LED.

## Two inputs, one state

VirtualButton has two independent control paths:

```text
Physical button -- local call --\
                                  > applyLedState() --> LED
iPhone app ------ BLE write -----/
                                           |
                                           v
                                  BLE notification --> iPhone UI
```

Both paths call `applyLedState()` in the firmware. That function updates the
GPIO, stores the new value in `ledState`, updates the characteristic, and
notifies a connected phone. Keeping those operations together prevents the
hardware and app from developing different ideas about the current state.

## Read, write, and notify

The LED characteristic supports three complementary operations:

| Operation | Direction | Purpose |
| --- | --- | --- |
| Read | ESP32 → iPhone | Learn the current state after connecting |
| Write | iPhone → ESP32 | Request an off, on, or toggle action |
| Notify | ESP32 → iPhone | Report later changes immediately |

After discovering the characteristic, `BLEManager` performs an initial read and
calls `setNotifyValue(true, for:)`. Incoming values reach
`didUpdateValueFor`, which changes the published `isLedOn` property. SwiftUI
then redraws the active ON or OFF control automatically.

## Experiment

1. Connect the iPhone and turn the LED on from the app.
2. Press the physical button without touching the phone.
3. Verify that the LED and app both change to off.
4. Disconnect the phone, press the physical button, and reconnect.
5. Verify that the initial read restores the correct state in the app.

Record whether each update came from a write, notification, or initial read.

## Discuss

- What stale information would the app show without notifications?
- Why is an initial read still required when notifications are enabled?
- Why does the ESP32 own the authoritative LED state?

## Success check

You can explain how a physical press reaches the SwiftUI view and why read plus
notify is more complete than either operation alone.
