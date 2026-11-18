"""Choose a simulator runtime and device type.

Usage: pick_device.py <ios-version-prefix> <preferred-device-name> <iPhone|iPad>
Prints: <runtime-id> <device-type-id> <label>
"""
import json
import subprocess
import sys

ver, want, family = sys.argv[1:4]


def simctl(*args):
    return json.loads(subprocess.check_output(["xcrun", "simctl", "list", *args, "-j"]))


runtimes = [
    r for r in simctl("runtimes")["runtimes"]
    if r.get("name", "").startswith("iOS ") and r["version"].startswith(ver) and r.get("isAvailable", True)
]
if not runtimes:
    sys.exit(f"iOS {ver} simulator runtime is not available on this runner")
rt = sorted(runtimes, key=lambda r: [int(x) for x in r["version"].split(".")])[-1]

supported = rt.get("supportedDeviceTypes")
if not supported:
    supported = [
        {"name": d["name"], "identifier": d["identifier"], "productFamily": d.get("productFamily", "")}
        for d in simctl("devicetypes")["devicetypes"]
    ]

pick = next((d for d in supported if d["name"] == want), None)
if pick is None:
    fam = [d for d in supported if d.get("productFamily") == family or d["name"].startswith(family)]
    if not fam:
        sys.exit(f"No {family} device type supports iOS {rt['version']}")
    pick = fam[-1]
    print(f"{want} is not available for iOS {rt['version']}; using {pick['name']}", file=sys.stderr)

label = f"{pick['name']}_iOS_{rt['version']}".replace(" ", "_")
print(rt["identifier"], pick["identifier"], label)
