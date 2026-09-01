#!/bin/zsh

set -euo pipefail

project_root="${0:A:h:h}"
build_dir="$project_root/.build/board-config-tests"
source_file="$project_root/tests/board_config_test.cpp"

mkdir -p "$build_dir"

clang++ -std=c++17 \
  -DEXPECTED_LED_PIN=4 \
  -DEXPECTED_BUTTON_PIN=25 \
  -DEXPECTED_LED_ON_LEVEL=1 \
  "$source_file" \
  -o "$build_dir/classic-esp32-test"

clang++ -std=c++17 \
  -DCONFIG_IDF_TARGET_ESP32C3=1 \
  -DEXPECTED_LED_PIN=4 \
  -DEXPECTED_BUTTON_PIN=3 \
  -DEXPECTED_LED_ON_LEVEL=1 \
  "$source_file" \
  -o "$build_dir/esp32-c3-test"

"$build_dir/classic-esp32-test"
"$build_dir/esp32-c3-test"

print "PASS: ESP32 board pin mappings match the documented wiring"
