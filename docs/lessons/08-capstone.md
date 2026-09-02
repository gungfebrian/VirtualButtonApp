# Unit 8: capstone investigation

## Learning goal

Demonstrate the complete VirtualButton system, diagnose one controlled failure,
and justify an extension using evidence from the hardware and software.

## Part 1: system demonstration

Build and run the project, then collect evidence for every row:

| Check | Prediction | Observation | Evidence |
| --- | --- | --- | --- |
| App ON command lights the LED | | | |
| App OFF command clears the LED | | | |
| Physical press toggles the LED once | | | |
| Physical press updates the app | | | |
| App reconnects to the saved board | | | |

Evidence can be a Serial Monitor line, a code reference, or an observation
repeated by another student. A result without evidence is not yet a conclusion.

## Part 2: trace one event

Choose either an app button tap or a physical button press. Draw or write the
event path from its input to every visible output. Include function names,
the BLE operation used, and the byte value when one is transmitted.

Use these prompts if needed:

- Where is the event first detected?
- Which component owns the authoritative LED state?
- When does data cross the BLE connection?
- What causes SwiftUI to redraw?

## Part 3: controlled failure

Select one reversible failure:

- change one character in the iPhone service UUID;
- disconnect the button wire;
- change `DEBOUNCE_MS` to 0; or
- give two boards the same advertised name.

Before making the change, predict the symptom. Test the prediction, restore the
original configuration, and explain why the system behaved that way. Never
move wiring while USB power is connected.

## Part 4: design an extension

Propose one small extension, such as a second LED, a brightness characteristic,
or a press counter. Your design must answer:

1. What new input, output, or state is introduced?
2. Does the existing characteristic still express the required data?
3. Which firmware and Swift files would change?
4. How would you verify the physical behavior and BLE behavior separately?
5. What safety or usability risk does the extension add?

Implementation is optional. The goal is to make the interface and test strategy
clear before writing code.

## Assessment guide

| Area | Complete when the student can… |
| --- | --- |
| Hardware | Explain the LED resistor and active-low button circuit |
| Firmware | Trace GPIO setup, debouncing, and `applyLedState()` |
| BLE | Identify central/peripheral roles and read/write/notify operations |
| App | Trace connection state and a command from SwiftUI to Core Bluetooth |
| Evidence | Separate a prediction, observation, and supported conclusion |
| Design | Define an extension with a focused verification strategy |

## Final reflection

In a short paragraph, explain how VirtualButton combines electrical state,
firmware state, BLE state, and interface state. Name the mechanism that keeps
those four views consistent.
