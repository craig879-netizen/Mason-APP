"""Print the download URL of an old (package-based) iOS simulator runtime from Apple's index.

Usage: legacy_runtime_url.py <ios-version> <path-to-index2.dvtdownloadableindex>
The index is at https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex
"""
import plistlib
import sys

ver, index_path = sys.argv[1:3]
with open(index_path, "rb") as f:
    index = plistlib.load(f)

for item in index.get("downloadables", []):
    name = item.get("name", "")
    words = name.split()
    if len(words) < 2 or words[0] != "iOS" or words[1] != ver or "Simulator" not in name:
        continue
    url = (item["source"]
           .replace("$(DOWNLOADABLE_IDENTIFIER)", item.get("identifier", ""))
           .replace("$(DOWNLOADABLE_VERSION)", item.get("version", "")))
    print(url)
    sys.exit(0)

sys.exit(f"Apple's index has no iOS {ver} simulator")
