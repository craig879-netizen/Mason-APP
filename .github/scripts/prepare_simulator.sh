#!/usr/bin/env bash
# Makes sure an iOS/iPadOS simulator runtime is installed, creates a device on it,
# and prints the new device's UDID.
# Usage: prepare_simulator.sh <ios-version-prefix> <preferred-device-name> <iPhone|iPad>
set -euo pipefail
VER=$1
DEVICE=$2
FAMILY=$3
HERE=$(cd "$(dirname "$0")" && pwd)
MAJOR=${VER%%.*}

runtime_installed() {
  xcrun simctl list runtimes | grep -q "^iOS $VER"
}

install_legacy_runtime() {
  # iOS 15 and older ship as installer packages that current macOS refuses to install.
  # Unpack the package and place the .simruntime bundle where CoreSimulator looks for it.
  local url work mnt pkg src dest
  work=$(mktemp -d)
  curl -fsSL --retry 3 -o "$work/index.plist" \
    https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex
  url=$(python3 "$HERE/legacy_runtime_url.py" "$VER" "$work/index.plist")
  mnt="$work/mnt"
  echo "Downloading $url" >&2
  curl -fL --retry 3 -o "$work/runtime.dmg" "$url" >&2
  hdiutil attach -nobrowse -readonly -mountpoint "$mnt" "$work/runtime.dmg" >&2
  pkg=$(find "$mnt" -maxdepth 1 -name '*.pkg' | head -1)
  pkgutil --expand-full "$pkg" "$work/expanded" >&2
  src=$(find "$work/expanded" -type d -name '*.simruntime' -prune | head -1)
  # In the old packages the payload itself is the bundle (Payload/Contents/Info.plist).
  if [ -z "$src" ] && [ -f "$work/expanded/Payload/Contents/Info.plist" ]; then
    src="$work/expanded/Payload"
  fi
  if [ -z "$src" ]; then
    echo "No .simruntime bundle found inside $pkg" >&2
    find "$work/expanded" -maxdepth 4 >&2
    exit 1
  fi
  dest="/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS $VER.simruntime"
  sudo mkdir -p "/Library/Developer/CoreSimulator/Profiles/Runtimes"
  sudo ditto "$src" "$dest"
  hdiutil detach "$mnt" >&2 || true
  rm -rf "$work"
  sudo killall -9 com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null || true
  sleep 5
}

if ! runtime_installed; then
  echo "iOS $VER runtime not installed; downloading it" >&2
  if [ "$MAJOR" -ge 16 ]; then
    xcodebuild -downloadPlatform iOS -buildVersion "$VER" >&2
  else
    install_legacy_runtime
  fi
  xcrun simctl list runtimes >&2
fi

read -r RUNTIME_ID DEVICE_TYPE_ID LABEL <<< "$(python3 "$HERE/pick_device.py" "$VER" "$DEVICE" "$FAMILY")"
echo "Creating $LABEL" >&2
xcrun simctl create "Mason-$LABEL" "$DEVICE_TYPE_ID" "$RUNTIME_ID"
