#pragma once

#include <stdint.h>

#if defined(CONFIG_IDF_TARGET_ESP32C3)
// External LED + button: easy to reproduce on common ESP32-C3 dev boards.
// Avoid GPIO 9 / BOOT so pressing the demo button cannot affect boot mode.
static constexpr uint8_t PIN_LED       = 4;
static constexpr uint8_t PIN_BUTTON    = 3;
static constexpr uint8_t LED_ON_LEVEL  = 1;
static constexpr uint8_t LED_OFF_LEVEL = 0;
#else
// GPIO 3 is the serial RX pin on the classic ESP32, so use GPIO 25 here.
static constexpr uint8_t PIN_LED       = 4;
static constexpr uint8_t PIN_BUTTON    = 25;
static constexpr uint8_t LED_ON_LEVEL  = 1;
static constexpr uint8_t LED_OFF_LEVEL = 0;
#endif
