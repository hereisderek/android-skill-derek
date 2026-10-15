#!/usr/bin/env bash
# Wake a sleeping Android device and unlock its lockscreen using a cached or supplied passcode.
# Reads/stores per-device passcodes in ~/.config/android-skill-derek/devices.json (mode 0600).

set -euo pipefail

CONFIG_DIR="${HOME}/.config/android-skill-derek"
DEVICES_FILE="${CONFIG_DIR}/devices.json"
mkdir -p "${CONFIG_DIR}"

TARGET_SERIAL="${ANDROID_SERIAL:-}"
PASSCODE="${ANDROID_DEVICE_PASSCODE:-}"
SAVE_PASSCODE="false"
STAY_AWAKE="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --serial|-s)
      TARGET_SERIAL="$2"
      shift 2
      ;;
    --passcode)
      PASSCODE="$2"
      SAVE_PASSCODE="true"
      shift 2
      ;;
    --no-stay-awake)
      STAY_AWAKE="false"
      shift 1
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
  echo '{"ok": false, "error": "No target Android device serial specified or connected."}'
  exit 1
fi

adb -s "${TARGET_SERIAL}" wait-for-device

# Save passcode to ~/.config/android-skill-derek/devices.json if newly provided
if [[ "${SAVE_PASSCODE}" == "true" ]] && [[ -n "${PASSCODE}" ]]; then
  python3 - "${DEVICES_FILE}" "${TARGET_SERIAL}" "${PASSCODE}" <<'PY'
import json, os, sys
path, serial, code = sys.argv[1], sys.argv[2], sys.argv[3]
data = {}
if os.path.exists(path):
    try:
        with open(path, "r") as f:
            data = json.load(f)
    except Exception:
        data = {}
devices = data.setdefault("devices", {})
entry = devices.setdefault(serial, {})
entry["passcode"] = code
with open(path, "w") as f:
    json.dump(data, f, indent=2)
os.chmod(path, 0o600)
PY
fi

# Load saved passcode if not passed on CLI
if [[ -z "${PASSCODE}" ]] && [[ -f "${DEVICES_FILE}" ]]; then
  PASSCODE=$(python3 - "${DEVICES_FILE}" "${TARGET_SERIAL}" <<'PY'
import json, sys
path, serial = sys.argv[1], sys.argv[2]
try:
    with open(path, "r") as f:
        data = json.load(f)
    print(data.get("devices", {}).get(serial, {}).get("passcode", ""))
except Exception:
    print("")
PY
)
fi

is_locked() {
  local win_dump
  win_dump=$(adb -s "${TARGET_SERIAL}" shell dumpsys window 2>/dev/null | tr -d '\r' || true)
  if echo "${win_dump}" | grep -Eq "mDreamingLockscreen=true|isStatusBarKeyguard=true|mShowingLockscreen=true"; then
    return 0
  fi
  local trust_dump
  trust_dump=$(adb -s "${TARGET_SERIAL}" shell dumpsys trust 2>/dev/null | tr -d '\r' || true)
  if echo "${trust_dump}" | grep -q "deviceLocked=1"; then
    return 0
  fi
  return 1
}

# 1. Wake up screen
adb -s "${TARGET_SERIAL}" shell input keyevent 224 >/dev/null 2>&1 || true
sleep 0.5

# 2. Keep screen awake during active testing if requested
if [[ "${STAY_AWAKE}" == "true" ]]; then
  adb -s "${TARGET_SERIAL}" shell svc power stayon true >/dev/null 2>&1 || true
fi

# 3. Try standard dismiss-keyguard and swipe up
adb -s "${TARGET_SERIAL}" shell wm dismiss-keyguard >/dev/null 2>&1 || true
adb -s "${TARGET_SERIAL}" shell input keyevent 82 >/dev/null 2>&1 || true
adb -s "${TARGET_SERIAL}" shell input swipe 500 1800 500 400 200 >/dev/null 2>&1 || true
sleep 1

# 4. If still locked, enter passcode if available
if is_locked; then
  if [[ -z "${PASSCODE}" ]]; then
    cat <<EOF
{
  "ok": false,
  "needs_passcode": true,
  "serial": "${TARGET_SERIAL}",
  "message": "Device ${TARGET_SERIAL} is locked with a PIN/passcode. Ask the user for the passcode and re-run with --passcode '<code_here>'."
}
EOF
    exit 2
  fi

  adb -s "${TARGET_SERIAL}" shell input keyevent 82 >/dev/null 2>&1 || true
  sleep 0.5
  adb -s "${TARGET_SERIAL}" shell input text "${PASSCODE}" >/dev/null 2>&1 || true
  adb -s "${TARGET_SERIAL}" shell input keyevent 66 >/dev/null 2>&1 || true
  sleep 1
fi

LOCKED_NOW="false"
if is_locked; then
  LOCKED_NOW="true"
fi

cat <<EOF
{
  "ok": $( [[ "${LOCKED_NOW}" == "false" ]] && echo "true" || echo "false" ),
  "serial": "${TARGET_SERIAL}",
  "is_locked": ${LOCKED_NOW},
  "stay_awake_enabled": ${STAY_AWAKE}
}
EOF
