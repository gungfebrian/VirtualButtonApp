#pragma once

#include <stdint.h>

#if defined(CONFIG_IDF_TARGET_ESP32C3)
static constexpr uint8_t PIN_LED       = 8;
static constexpr uint8_t PIN_BUTTON    = 9;
static constexpr uint8_t LED_ON_LEVEL  = 0;
static constexpr uint8_t LED_OFF_LEVEL = 1;
#else
static constexpr uint8_t PIN_LED       = 4;
static constexpr uint8_t PIN_BUTTON    = 25;
static constexpr uint8_t LED_ON_LEVEL  = 1;
static constexpr uint8_t LED_OFF_LEVEL = 0;
#endif
