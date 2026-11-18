"""Print the UDID of the best available iOS 26+ iPhone simulator (prefers iPhone 17 Pro)."""
import json
import re
import subprocess
import sys

data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))
best = None
for runtime, devices in data["devices"].items():
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not m or int(m.group(1)) < 26:
        continue
    version = (int(m.group(1)), int(m.group(2)))
    for dev in devices:
        if not dev.get("isAvailable", True) or not dev["name"].startswith("iPhone"):
            continue
        score = (version, dev["name"] == "iPhone 17 Pro", "Pro" in dev["name"])
        if best is None or score > best[0]:
            best = (score, dev["udid"], dev["name"], runtime)

if best is None:
    sys.exit("No iOS 26 iPhone simulator is installed on this runner.")
print(f"Using {best[2]} ({best[3]})", file=sys.stderr)
print(best[1])
