#include "../esp32_ble_led/board_config.h"

#ifndef EXPECTED_LED_PIN
#error "EXPECTED_LED_PIN must be defined"
#endif

#ifndef EXPECTED_BUTTON_PIN
#error "EXPECTED_BUTTON_PIN must be defined"
#endif

#ifndef EXPECTED_LED_ON_LEVEL
#error "EXPECTED_LED_ON_LEVEL must be defined"
#endif

static_assert(PIN_LED == EXPECTED_LED_PIN, "unexpected LED pin");
static_assert(PIN_BUTTON == EXPECTED_BUTTON_PIN, "unexpected button pin");
static_assert(LED_ON_LEVEL == EXPECTED_LED_ON_LEVEL, "unexpected LED polarity");

int main() { return 0; }
