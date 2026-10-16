#!/usr/bin/env bash
# Manage test device pool across:
# 1. Remote StageDroid devices (discovered via device-check.sh /api/discovery Virtual adbd ports or Central Proxy 50370)
# 2. Local USB / Wireless ADB devices
# 3. Android Virtual Devices (AVDs) booted on-demand via Google Android CLI (emulator / avdmanager)
# Tracks leases in the long-lived coordinator cache: ~/.config/android-skill-derek/cache/device-leases.json.

set -euo pipefail

CONFIG_DIR="${HOME}/.config/android-skill-derek"
CACHE_DIR="${CONFIG_DIR}/cache"
LEASES_FILE="${CACHE_DIR}/device-leases.json"
mkdir -p "${CACHE_DIR}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ACTION="${1:-list}"
shift || true

OWNER="coordinator"
TARGET_SERIAL=""
AVD_NAME=""
BOOT_IF_NONE="true"
TO_OWNER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner)
      OWNER="$2"
      shift 2
      ;;
    --to)
      TO_OWNER="$2"
      shift 2
      ;;
    --serial|-s)
      TARGET_SERIAL="$2"
      shift 2
      ;;
    --avd)
      AVD_NAME="$2"
      shift 2
      ;;
    --no-boot-avd)
      BOOT_IF_NONE="false"
      shift 1
      ;;
    *)
      echo "Unknown flag: $1" >&2
      exit 1
      ;;
  esac
done

find_sdk_tool() {
  local tool="$1"
  if command -v "$tool" >/dev/null 2>&1; then
    command -v "$tool"
    return 0
  fi
  for sdk_root in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "${HOME}/Library/Android/sdk" "${HOME}/Android/Sdk"; do
    if [[ -n "$sdk_root" ]] && [[ -d "$sdk_root" ]]; then
      for subdir in "emulator" "cmdline-tools/latest/bin" "tools/bin" "platform-tools"; do
        if [[ -x "${sdk_root}/${subdir}/${tool}" ]]; then
          echo "${sdk_root}/${subdir}/${tool}"
          return 0
        fi
      done
    fi
  done
  return 1
}

EMULATOR_BIN=$(find_sdk_tool emulator || true)
AVDMANAGER_BIN=$(find_sdk_tool avdmanager || true)
STAGEDROID_INFO=$(bash "${SCRIPT_DIR}/device-check.sh" 2>/dev/null || echo "{}")

python3 - "${ACTION}" "${LEASES_FILE}" "${OWNER}" "${TARGET_SERIAL}" "${AVD_NAME}" "${BOOT_IF_NONE}" "${EMULATOR_BIN}" "${AVDMANAGER_BIN}" "${STAGEDROID_INFO}" "${TO_OWNER}" <<'PY'
import json, os, subprocess, sys, time
from urllib.parse import urlparse

action, leases_file, owner, req_serial, avd_name, boot_if_none, emulator_bin, avdmanager_bin, sd_raw, to_owner = sys.argv[1:11]

def load_leases():
    if os.path.exists(leases_file):
        try:
            with open(leases_file, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {"leases": {}, "updated_at": 0}

def save_leases(data):
    data["updated_at"] = int(time.time())
    with open(leases_file, "w") as f:
        json.dump(data, f, indent=2)

# Auto-connect StageDroid Virtual adbd ports if StageDroid discovery returned devices
sd_devices = []
try:
    sd_data = json.loads(sd_raw).get("stagedroid", {})
    base_url = sd_data.get("base_url", "")
    disc = sd_data.get("discovery", {}) or {}
    host = urlparse(base_url).hostname if base_url else None
    for d in disc.get("devices", []) or []:
        adb_port = d.get("adbPort")
        if host and adb_port:
            endpoint = f"{host}:{adb_port}"
            sd_devices.append(endpoint)
            subprocess.run(["adb", "connect", endpoint], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
except Exception:
    pass

def connected_adb_devices():
    try:
        out = subprocess.check_output(["adb", "devices"], text=True)
        devs = []
        for line in out.splitlines()[1:]:
            parts = line.split()
            if len(parts) >= 2 and parts[1] == "device":
                devs.append(parts[0])
        return devs
    except Exception:
        return []

def available_avds():
    if not emulator_bin:
        return []
    try:
        out = subprocess.check_output([emulator_bin, "-list-avds"], text=True)
        return [line.strip() for line in out.splitlines() if line.strip()]
    except Exception:
        return []

state = load_leases()
leases = state.setdefault("leases", {})
online = connected_adb_devices()
avds = available_avds()

# Keep long-lived cache (only prune disconnected leases older than 12 hours)
now = int(time.time())
for s in list(leases.keys()):
    if s not in online and (now - leases[s].get("leased_at", now)) > 43200:
        del leases[s]

if action == "list":
    save_leases(state)
    print(json.dumps({
        "online_devices": online,
        "stagedroid_virtual_adbd_devices": sd_devices,
        "available_avds": avds,
        "emulator_cli": emulator_bin,
        "avdmanager_cli": avdmanager_bin,
        "active_leases": leases
    }, indent=2))
    sys.exit(0)

elif action == "release":
    if req_serial and req_serial in leases:
        del leases[req_serial]
    else:
        for s in list(leases.keys()):
            if leases[s].get("owner") == owner:
                del leases[s]
    save_leases(state)
    print(json.dumps({"ok": True, "released_serial": req_serial, "owner": owner, "active_leases": leases}))
    sys.exit(0)

elif action == "transfer":
    target = req_serial
    if not target:
        for s, info in leases.items():
            if info.get("owner") == owner:
                target = s
                break
    if not target or target not in leases:
        print(json.dumps({
            "ok": False,
            "error": f"No active lease found to transfer for owner '{owner}' / serial '{req_serial}'.",
            "active_leases": leases
        }))
        sys.exit(1)
    new_owner = to_owner if to_owner else "coordinator"
    leases[target] = {"owner": new_owner, "leased_at": now}
    save_leases(state)
    print(json.dumps({"ok": True, "serial": target, "from": owner, "to": new_owner, "active_leases": leases}))
    sys.exit(0)

elif action == "lease":
    chosen = None
    for s in online:
        if leases.get(s, {}).get("owner") == owner:
            chosen = s
            break
    if not chosen and req_serial and req_serial in online and req_serial not in leases:
        chosen = req_serial
    if not chosen:
        for s in online:
            if s not in leases:
                chosen = s
                break
    if not chosen and boot_if_none == "true" and emulator_bin and avds:
        target_avd = avd_name if avd_name in avds else avds[0]
        before = set(online)
        subprocess.Popen(
            [emulator_bin, "-avd", target_avd, "-no-snapshot-save", "-no-boot-anim"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        for _ in range(45):
            time.sleep(2)
            curr = set(connected_adb_devices())
            new_devs = curr - before
            if new_devs:
                cand = sorted(new_devs)[0]
                try:
                    booted = subprocess.check_output(
                        ["adb", "-s", cand, "shell", "getprop", "sys.boot_completed"],
                        text=True
                    ).strip()
                    if booted == "1":
                        chosen = cand
                        break
                except Exception:
                    pass

    if not chosen:
        print(json.dumps({
            "ok": False,
            "error": "No unleased test device available and no AVD could be booted.",
            "online_devices": online,
            "active_leases": leases,
            "available_avds": avds
        }))
        sys.exit(1)

    leases[chosen] = {"owner": owner, "leased_at": now}
    save_leases(state)
    print(json.dumps({"ok": True, "serial": chosen, "owner": owner, "active_leases": leases}))
PY
