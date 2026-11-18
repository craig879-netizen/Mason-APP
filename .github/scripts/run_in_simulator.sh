#!/usr/bin/env bash
# Boots an iOS simulator, installs Mason, opens each screen and screenshots it.
# Usage: run_in_simulator.sh <udid> <path/to/Mason.app> <output-dir>
set -euo pipefail
UDID=$1
APP=$2
OUT=$3
BUNDLE=com.mason.app

mkdir -p "$OUT"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged \
  --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true
xcrun simctl install "$UDID" "$APP"

shot() {
  local name=$1; shift
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" "$@"
  sleep 6
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png"
  echo "Captured $name"
}

for mode in light dark; do
  xcrun simctl ui "$UDID" appearance "$mode"
  shot "$mode-1-home"        -tab home
  shot "$mode-2-tasks"       -tab tasks
  shot "$mode-3-new-task"    -tab home -sheet
  shot "$mode-4-settings"    -tab settings
done

xcrun simctl shutdown "$UDID" || true
