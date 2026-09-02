# Unit 5: mechanical bounce and debouncing

## Learning goal

Explain why one physical press can produce several electrical transitions and
trace the firmware state used to accept only a stable input.

## The hidden motion inside a switch

Button contacts are pieces of metal. When they meet, they can bounce for a few
milliseconds before settling. A fast microcontroller may read that movement as
several presses:

```text
Ideal press:  HIGH ---------------- LOW
Real press:   HIGH -------- LOW HIGH LOW HIGH LOW
                                 <--- bounce --->
```

Without debouncing, one press could toggle the LED multiple times and leave it
in an unpredictable final state.

## Follow the algorithm

`handleButton()` separates the latest electrical sample from the accepted
button state:

| Variable | Meaning |
| --- | --- |
| `raw` | The input read during this loop |
| `lastRawButton` | The previous raw sample |
| `stableButton` | The state accepted by the application |
| `lastDebounceAt` | When the raw input last changed |
| `DEBOUNCE_MS` | Required stable time: 50 ms |

Every raw transition restarts the timer. The firmware changes `stableButton`
only after the same raw value lasts for at least 50 ms. It toggles the LED only
on the accepted `HIGH` to `LOW` transition, which represents a press.

## Predict the state

For each sample below, decide whether the stable state should change:

| Time | Raw reading | Time stable | Accepted? |
| ---: | --- | ---: | --- |
| 0 ms | `HIGH` | — | Initial state |
| 10 ms | `LOW` | 0 ms | No |
| 18 ms | `HIGH` | 0 ms | No |
| 25 ms | `LOW` | 0 ms | No |
| 75 ms | `LOW` | 50 ms | Yes: pressed |

## Experiment

1. Change `DEBOUNCE_MS` from 50 to 0 and upload the sketch.
2. Press the physical button repeatedly while watching the LED and Serial
   Monitor.
3. Restore 50 ms and compare the behavior.
4. Try 500 ms and explain why a value can be too large as well as too small.

Hardware varies, so observations may differ. Record results instead of claiming
that one timing value is universal.

## Discuss

- Why does the timer restart whenever the raw value changes?
- Why does the action happen on press rather than both press and release?
- What trade-off increases when the debounce interval becomes longer?

## Success check

You can use the raw and stable states to explain why a bouncing transition
causes exactly one LED toggle.
