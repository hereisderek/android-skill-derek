#!/usr/bin/env bash
# Serialized Coordinator Gate 2 On-Device Verification Helper
# 1. Leases/locks the target device (or boots an AVD if needed)
# 2. Wakes sleeping screen and unlocks passcode lockscreen
# 3. Installs debug APK & runs connectedDebugAndroidTest
# 4. Launches app & Component Gallery, captures screenshots/hierarchy, and optionally runs multi-density UI audit
# 5. Audits logcat for crashes/ANRs

set -euo pipefail

PROJECT_DIR="."
PACKAGE_NAME=""
GALLERY_ACTIVITY=""
TARGET_SERIAL="${ANDROID_SERIAL:-}"
PASSCODE="${ANDROID_DEVICE_PASSCODE:-}"
RUN_CONNECTED_TESTS="true"
RUN_UI_AUDIT="false"
OUTPUT_DIR="/tmp"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir)
      PROJECT_DIR="$2"
      shift 2
      ;;
    --package)
      PACKAGE_NAME="$2"
      shift 2
      ;;
    --gallery-activity)
      GALLERY_ACTIVITY="$2"
      shift 2
      ;;
    --serial|-s)
      TARGET_SERIAL="$2"
      shift 2
      ;;
    --passcode)
      PASSCODE="$2"
      shift 2
      ;;
    --skip-connected-tests)
      RUN_CONNECTED_TESTS="false"
      shift 1
      ;;
    --run-ui-audit)
      RUN_UI_AUDIT="true"
      shift 1
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Lease or resolve device from pool
if [[ -z "${TARGET_SERIAL}" ]]; then
  LEASE_JSON=$(bash "${SCRIPT_DIR}/device-pool.sh" lease --owner "coordinator-gate2")
  TARGET_SERIAL=$(echo "${LEASE_JSON}" | grep -o '"serial"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*"([^"]*)"$/\1/')
fi

LOCK_SAFE=$(echo "${TARGET_SERIAL}" | tr ':./' '___')
LOCK_DIR="/tmp/android-device-${LOCK_SAFE}.lock.d"

WAIT_SECS=0
while ! mkdir "${LOCK_DIR}" 2>/dev/null; do
  sleep 2
  WAIT_SECS=$((WAIT_SECS + 2))
  if [[ ${WAIT_SECS} -ge 300 ]]; then
    echo "Timed out waiting for device lock ${LOCK_DIR}" >&2
    exit 1
  fi
done
trap 'rmdir "${LOCK_DIR}" 2>/dev/null || true' EXIT

# 2. Wake and unlock device before running tests
WAKE_ARGS=(--serial "${TARGET_SERIAL}")
[[ -n "${PASSCODE}" ]] && WAKE_ARGS+=(--passcode "${PASSCODE}")
bash "${SCRIPT_DIR}/device-wake-unlock.sh" "${WAKE_ARGS[@]}"

cd "${PROJECT_DIR}"
export ANDROID_SERIAL="${TARGET_SERIAL}"

# 3. Install Debug APK and run instrumentation tests
if [[ -x "./gradlew" ]]; then
  ./gradlew installDebug
  if [[ "${RUN_CONNECTED_TESTS}" == "true" ]]; then
    ./gradlew connectedDebugAndroidTest
  fi
fi

adb -s "${TARGET_SERIAL}" logcat -c

# 4. Launch main app (and optional Component Gallery activity)
if [[ -n "${PACKAGE_NAME}" ]]; then
  adb -s "${TARGET_SERIAL}" shell monkey -p "${PACKAGE_NAME}" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
  sleep 3
fi

SCREENSHOT_PATH="${OUTPUT_DIR}/device_screen_verify.png"
HIERARCHY_PATH="${OUTPUT_DIR}/window_dump.xml"
LOGCAT_ERROR_PATH="${OUTPUT_DIR}/device_error_logcat.txt"

adb -s "${TARGET_SERIAL}" exec-out screencap -p > "${SCREENSHOT_PATH}"
adb -s "${TARGET_SERIAL}" shell uiautomator dump /sdcard/window_dump.xml >/dev/null 2>&1 || true
adb -s "${TARGET_SERIAL}" pull /sdcard/window_dump.xml "${HIERARCHY_PATH}" >/dev/null 2>&1 || true

GALLERY_SCREENSHOT_PATH=""
if [[ -n "${GALLERY_ACTIVITY}" ]] && [[ -n "${PACKAGE_NAME}" ]]; then
  adb -s "${TARGET_SERIAL}" shell am start -n "${PACKAGE_NAME}/${GALLERY_ACTIVITY}" >/dev/null 2>&1 || true
  sleep 2
  GALLERY_SCREENSHOT_PATH="${OUTPUT_DIR}/device_gallery_verify.png"
  adb -s "${TARGET_SERIAL}" exec-out screencap -p > "${GALLERY_SCREENSHOT_PATH}"
fi

if [[ "${RUN_UI_AUDIT}" == "true" ]]; then
  bash "${SCRIPT_DIR}/device-ui-audit.sh" --serial "${TARGET_SERIAL}" --package "${PACKAGE_NAME}" --output-dir "${OUTPUT_DIR}/ui-audit" >/dev/null
fi

adb -s "${TARGET_SERIAL}" logcat -d *:E > "${LOGCAT_ERROR_PATH}" || true

cat <<EOF
{
  "ok": true,
  "serial": "${TARGET_SERIAL}",
  "screenshot": "${SCREENSHOT_PATH}",
  "gallery_screenshot": "${GALLERY_SCREENSHOT_PATH}",
  "ui_hierarchy": "${HIERARCHY_PATH}",
  "error_logcat": "${LOGCAT_ERROR_PATH}"
}
EOF
