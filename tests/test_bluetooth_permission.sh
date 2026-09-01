#!/bin/zsh

set -euo pipefail

project_root="${0:A:h:h}"
derived_data="$project_root/.build/test-derived-data"
expected="VirtualButton uses Bluetooth to discover and control nearby IOT101 boards."

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild \
  -project "$project_root/VirtualButton.xcodeproj" \
  -scheme VirtualButton \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  -quiet \
  build

info_plist="$derived_data/Build/Products/Debug-iphonesimulator/VirtualButton.app/Info.plist"

if ! actual=$(/usr/libexec/PlistBuddy -c 'Print :NSBluetoothAlwaysUsageDescription' "$info_plist" 2>/dev/null); then
  print -u2 "FAIL: built app is missing NSBluetoothAlwaysUsageDescription"
  exit 1
fi

if [[ "$actual" != "$expected" ]]; then
  print -u2 "FAIL: unexpected Bluetooth permission message: $actual"
  exit 1
fi

print "PASS: built app contains the Bluetooth permission message"
