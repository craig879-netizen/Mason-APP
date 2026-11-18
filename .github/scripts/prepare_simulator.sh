#!/usr/bin/env bash
# Makes sure an iOS/iPadOS simulator runtime is installed, creates a device on it,
# and prints the new device's UDID.
# Usage: prepare_simulator.sh <ios-version-prefix> <preferred-device-name> <iPhone|iPad>
set -euo pipefail
VER=$1
DEVICE=$2
FAMILY=$3

runtime_installed() {
  xcrun simctl list runtimes -j | python3 -c '
import json, sys
v = sys.argv[1]
rts = json.load(sys.stdin)["runtimes"]
ok = any(r.get("name", "").startswith("iOS ") and r["version"].startswith(v) and r.get("isAvailable", True) for r in rts)
print("yes" if ok else "no")' "$VER"
}

if [ "$(runtime_installed)" != "yes" ]; then
  echo "iOS $VER runtime not installed; downloading it" >&2
  if ! xcodebuild -downloadPlatform iOS -buildVersion "$VER" >&2; then
    command -v xcodes >/dev/null || brew install xcodesorg/made/xcodes >&2
    sudo xcodes runtimes install "iOS $VER" >&2
  fi
fi

xcrun simctl list runtimes -j > /tmp/runtimes.json
xcrun simctl list devicetypes -j > /tmp/devicetypes.json

read -r RUNTIME_ID DEVICE_TYPE_ID LABEL < <(python3 - "$VER" "$DEVICE" "$FAMILY" <<'PY'
import json, sys
ver, want, family = sys.argv[1:]
runtimes = [r for r in json.load(open("/tmp/runtimes.json"))["runtimes"]
            if r.get("name", "").startswith("iOS ") and r["version"].startswith(ver) and r.get("isAvailable", True)]
if not runtimes:
    sys.exit(f"iOS {ver} simulator runtime is not available on this runner")
rt = sorted(runtimes, key=lambda r: [int(x) for x in r["version"].split(".")])[-1]
supported = rt.get("supportedDeviceTypes") or [
    {"name": d["name"], "identifier": d["identifier"], "productFamily": d.get("productFamily", "")}
    for d in json.load(open("/tmp/devicetypes.json"))["devicetypes"]]
pick = next((d for d in supported if d["name"] == want), None)
if pick is None:
    fam = [d for d in supported if d.get("productFamily") == family or d["name"].startswith(family)]
    if not fam:
        sys.exit(f"No {family} device type supports iOS {rt['version']}")
    pick = fam[-1]
print(rt["identifier"], pick["identifier"], (pick["name"] + "_iOS_" + rt["version"]).replace(" ", "_"))
PY
)

echo "Creating $LABEL" >&2
xcrun simctl create "Mason-$LABEL" "$DEVICE_TYPE_ID" "$RUNTIME_ID"
