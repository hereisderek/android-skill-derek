#!/usr/bin/env bash
# Multi-screen, density, font-scale, status bar, display cutout, and bottom nav bar UI auditor.
# Checks for text/edge clipping across screen profiles and resets display overrides on exit.

set -euo pipefail

TARGET_SERIAL="${ANDROID_SERIAL:-}"
PACKAGE_NAME=""
OUTPUT_DIR="/tmp/ui-audit"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --serial|-s)
      TARGET_SERIAL="$2"
      shift 2
      ;;
    --package)
      PACKAGE_NAME="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown flag: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${TARGET_SERIAL}" ]]; then
  TARGET_SERIAL=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}' || true)
fi

if [[ -z "${TARGET_SERIAL}" ]]; then
  echo '{"ok": false, "error": "No connected Android device found."}'
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

# Always restore hardware screen size, density, and font scale on exit
cleanup_display() {
  adb -s "${TARGET_SERIAL}" shell wm size reset >/dev/null 2>&1 || true
  adb -s "${TARGET_SERIAL}" shell wm density reset >/dev/null 2>&1 || true
  adb -s "${TARGET_SERIAL}" shell settings put system font_scale 1.0 >/dev/null 2>&1 || true
}
trap cleanup_display EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/device-wake-unlock.sh" --serial "${TARGET_SERIAL}" >/dev/null 2>&1 || true

# Capture Window Insets (Status Bar, Display Cutout, Navigation Bar)
WINDOW_DUMP_RAW="${OUTPUT_DIR}/dumpsys_window_insets.txt"
adb -s "${TARGET_SERIAL}" shell dumpsys window windows | grep -E "Frames|Insets|mDisplayCutout|StatusBar|NavigationBar|displayCutout" > "${WINDOW_DUMP_RAW}" 2>/dev/null || true

PROFILES=(
  "default:reset:reset:1.0"
  "compact_phone:1080x1920:420:1.0"
  "high_density_font130:1080x2400:480:1.3"
  "tablet_foldable:1800x2560:320:1.0"
)

for entry in "${PROFILES[@]}"; do
  IFS=":" read -r label size dpi fscale <<< "${entry}"
  if [[ "${size}" == "reset" ]]; then
    adb -s "${TARGET_SERIAL}" shell wm size reset >/dev/null 2>&1 || true
  else
    adb -s "${TARGET_SERIAL}" shell wm size "${size}" >/dev/null 2>&1 || true
  fi
  if [[ "${dpi}" == "reset" ]]; then
    adb -s "${TARGET_SERIAL}" shell wm density reset >/dev/null 2>&1 || true
  else
    adb -s "${TARGET_SERIAL}" shell wm density "${dpi}" >/dev/null 2>&1 || true
  fi
  adb -s "${TARGET_SERIAL}" shell settings put system font_scale "${fscale}" >/dev/null 2>&1 || true
  sleep 1.5

  adb -s "${TARGET_SERIAL}" exec-out screencap -p > "${OUTPUT_DIR}/screen_${label}.png"
  adb -s "${TARGET_SERIAL}" shell uiautomator dump "/sdcard/dump_${label}.xml" >/dev/null 2>&1 || true
  adb -s "${TARGET_SERIAL}" pull "/sdcard/dump_${label}.xml" "${OUTPUT_DIR}/dump_${label}.xml" >/dev/null 2>&1 || true
done

# Analyze XML hierarchy dumps for off-screen / clipped bounds or text cutoff indicators
python3 - "${OUTPUT_DIR}" <<'PY'
import glob, json, os, re, sys, xml.etree.ElementTree as ET

out_dir = sys.argv[1]
reports = {}

for xml_path in sorted(glob.glob(os.path.join(out_dir, "dump_*.xml"))):
    profile = os.path.basename(xml_path)[5:-4]
    clipped = []
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
        # Infer viewport bounds from root node
        max_w, max_h = 1080, 2400
        for elem in root.iter("node"):
            b = elem.attrib.get("bounds", "")
            m = re.match(r"\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]", b)
            if not m:
                continue
            x1, y1, x2, y2 = map(int, m.groups())
            if elem == root or elem.attrib.get("index") == "0" and x1 == 0 and y1 == 0 and x2 > 0 and y2 > 0:
                max_w = max(max_w, x2)
                max_h = max(max_h, y2)
            # Flag visible text/clickable nodes extending outside screen edges or collapsed to 0px
            text = elem.attrib.get("text", "")
            res_id = elem.attrib.get("resource-id", "")
            if (text or elem.attrib.get("clickable") == "true"):
                if x1 < 0 or y1 < 0 or x2 > max_w or y2 > max_h or (x2 - x1) <= 2 or (y2 - y1) <= 2:
                    clipped.append({
                        "resource_id": res_id,
                        "text": text[:40],
                        "bounds": b,
                        "screen_bounds": f"[0,0][{max_w},{max_h}]"
                    })
    except Exception as e:
        clipped.append({"parse_error": str(e)})
    reports[profile] = {
        "screenshot": os.path.join(out_dir, f"screen_{profile}.png"),
        "hierarchy_xml": xml_path,
        "potential_clipped_nodes": clipped[:15]
    }

print(json.dumps({
    "ok": True,
    "output_dir": out_dir,
    "insets_dump": os.path.join(out_dir, "dumpsys_window_insets.txt"),
    "profiles_tested": reports
}, indent=2))
PY
