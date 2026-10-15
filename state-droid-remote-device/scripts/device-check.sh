#!/usr/bin/env bash
# Discover StageDroid via mDNS (_stagedroid._tcp), environment variables (STAGEDROID_HOST/PORT),
# saved ~/.config/android-skill-derek/config.json, or local ports (3000/3443).
# Prefers current official GitHub SKILL.md, then live /skill, then the bundled snapshot; also queries /status and /api/discovery,
# and reports both StageDroid Central ADB Proxy (50370) / Virtual adbd (51001+) and local ADB targets.

set -euo pipefail

CONFIG_DIR="${HOME}/.config/android-skill-derek"
CONFIG_FILE="${CONFIG_DIR}/config.json"
CACHE_DIR="${CONFIG_DIR}/cache"
mkdir -p "${CACHE_DIR}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAPSHOT_SKILL="${SCRIPT_DIR}/../assets/stagedroid-snapshot.md"
LIVE_SKILL_CACHE="${CACHE_DIR}/stagedroid-live-skill.md"
GITHUB_SKILL_CACHE="${CACHE_DIR}/stagedroid-github-skill.md"
GITHUB_REPO_URL="https://github.com/hereisderek/StageDroid"
GITHUB_API_LATEST_RELEASE_URL="https://api.github.com/repos/hereisderek/StageDroid/releases/latest"
GITHUB_SKILL_REF="${STAGEDROID_GITHUB_REF:-}"
GITHUB_SKILL_URL=""

STAGEDROID_HOST_VAL="${STAGEDROID_HOST:-}"
STAGEDROID_PORT_VAL="${STAGEDROID_PORT:-3000}"
STAGEDROID_HTTPS_PORT_VAL="${STAGEDROID_HTTPS_PORT:-3443}"
STAGEDROID_PROXY_PORT_VAL="${STAGEDROID_ADB_PROXY_PORT:-50370}"
MDNS_SERVICE="${STAGEDROID_MDNS_SERVICE:-_stagedroid._tcp}"
STAGEDROID_BASE_URL=""

# 1. Load saved StageDroid URL / host from ~/.config/android-skill-derek/config.json if present
if [[ -f "${CONFIG_FILE}" ]]; then
  SAVED_URL=$(grep -o '"stagedroid_url"[[:space:]]*:[[:space:]]*"[^"]*"' "${CONFIG_FILE}" | sed -E 's/.*"([^"]*)"$/\1/' || true)
  [[ -n "${SAVED_URL}" ]] && STAGEDROID_BASE_URL="${SAVED_URL%/}"
fi

if [[ -z "${STAGEDROID_BASE_URL}" ]] && [[ -n "${STAGEDROID_HOST_VAL}" ]]; then
  STAGEDROID_BASE_URL="http://${STAGEDROID_HOST_VAL}:${STAGEDROID_PORT_VAL}"
fi

# 2. Step 0 from StageDroid SKILL.md: Auto-Discover via mDNS (_stagedroid._tcp)
MDNS_DISCOVERED=""
if [[ -z "${STAGEDROID_BASE_URL}" ]]; then
  if command -v dns-sd >/dev/null 2>&1; then
    BROWSE_OUT=$( (dns-sd -B "${MDNS_SERVICE}" local. & PID=$!; sleep 2; kill $PID 2>/dev/null || true) 2>/dev/null || true )
    if echo "${BROWSE_OUT}" | grep -q "Add"; then
      INSTANCE_NAME=$(echo "${BROWSE_OUT}" | awk '/Add/ {print substr($0, index($0,$7)); exit}' | sed 's/[[:space:]]*$//')
      RESOLVE_OUT=$( (dns-sd -L "${INSTANCE_NAME}" "${MDNS_SERVICE}" local. & PID=$!; sleep 2; kill $PID 2>/dev/null || true) 2>/dev/null || true )
      HOST_PORT=$(echo "${RESOLVE_OUT}" | grep -oE 'can be reached at [^ ]+' | awk '{print $4}' | head -n 1 || true)
      if [[ -n "${HOST_PORT}" ]]; then
        MDNS_DISCOVERED="${HOST_PORT}"
        STAGEDROID_BASE_URL="http://${HOST_PORT}"
      fi
    fi
  elif command -v avahi-browse >/dev/null 2>&1; then
    AVAHI_OUT=$(avahi-browse -rt "${MDNS_SERVICE}" -p 2>/dev/null | awk -F';' '/^=/ {print $8 ":" $9; exit}' || true)
    if [[ -n "${AVAHI_OUT}" ]]; then
      MDNS_DISCOVERED="${AVAHI_OUT}"
      STAGEDROID_BASE_URL="http://${AVAHI_OUT}"
    fi
  fi
fi

# 3. Step 2 from StageDroid SKILL.md: Test Local Fallbacks (127.0.0.1:3000 or 3443)
if [[ -z "${STAGEDROID_BASE_URL}" ]]; then
  if curl -fsS --max-time 2 "http://127.0.0.1:${STAGEDROID_PORT_VAL}/api/status" >/dev/null 2>&1; then
    STAGEDROID_BASE_URL="http://127.0.0.1:${STAGEDROID_PORT_VAL}"
  elif curl -k -fsS --max-time 2 "https://127.0.0.1:${STAGEDROID_HTTPS_PORT_VAL}/api/status" >/dev/null 2>&1; then
    STAGEDROID_BASE_URL="https://127.0.0.1:${STAGEDROID_HTTPS_PORT_VAL}"
  fi
fi

# 4. Resolve capability instructions: official GitHub first, live /skill second, bundled snapshot last.
LIVE_SKILL_OK="false"
GITHUB_SKILL_OK="false"
DISCOVERY_JSON="{}"
STATUS_JSON="{}"
SKILL_SOURCE_USED="${SNAPSHOT_SKILL}"

if [[ -z "${GITHUB_SKILL_REF}" ]]; then
  LATEST_RELEASE_JSON=$(curl -fsSL --max-time 5 "${GITHUB_API_LATEST_RELEASE_URL}" 2>/dev/null || true)
  GITHUB_SKILL_REF=$(printf '%s' "${LATEST_RELEASE_JSON}" | sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -n 1)
fi
[[ -z "${GITHUB_SKILL_REF}" ]] && GITHUB_SKILL_REF="main"
GITHUB_SKILL_URL="https://raw.githubusercontent.com/hereisderek/StageDroid/${GITHUB_SKILL_REF}/SKILL.md"

if curl -fsSL --max-time 5 "${GITHUB_SKILL_URL}" -o "${GITHUB_SKILL_CACHE}" 2>/dev/null; then
  GITHUB_SKILL_OK="true"
  SKILL_SOURCE_USED="${GITHUB_SKILL_CACHE}"
elif [[ "${GITHUB_SKILL_REF}" != "main" ]]; then
  GITHUB_SKILL_REF="main"
  GITHUB_SKILL_URL="https://raw.githubusercontent.com/hereisderek/StageDroid/${GITHUB_SKILL_REF}/SKILL.md"
  if curl -fsSL --max-time 5 "${GITHUB_SKILL_URL}" -o "${GITHUB_SKILL_CACHE}" 2>/dev/null; then
    GITHUB_SKILL_OK="true"
    SKILL_SOURCE_USED="${GITHUB_SKILL_CACHE}"
  fi
fi

if [[ -n "${STAGEDROID_BASE_URL}" ]]; then
  if [[ "${GITHUB_SKILL_OK}" != "true" ]] && curl -k -fsS --max-time 3 "${STAGEDROID_BASE_URL}/skill" -o "${LIVE_SKILL_CACHE}" 2>/dev/null; then
    LIVE_SKILL_OK="true"
    SKILL_SOURCE_USED="${LIVE_SKILL_CACHE}"
  fi
  DISCOVERY_JSON=$(curl -k -fsS --max-time 3 "${STAGEDROID_BASE_URL}/api/discovery" 2>/dev/null || echo "{}")
  STATUS_JSON=$(curl -k -fsS --max-time 3 "${STAGEDROID_BASE_URL}/status" 2>/dev/null || curl -k -fsS --max-time 3 "${STAGEDROID_BASE_URL}/api/status" 2>/dev/null || echo "{}")
fi

# 5. Report upstream accessibility and the source actually selected.
GITHUB_PUBLIC="false"
if curl -fsSI --max-time 3 "${GITHUB_REPO_URL}" >/dev/null 2>&1; then
  GITHUB_PUBLIC="true"
fi

cat <<EOF
{
  "stagedroid": {
    "github_repo": "${GITHUB_REPO_URL}",
    "github_is_public": ${GITHUB_PUBLIC},
    "github_skill_ref": "${GITHUB_SKILL_REF}",
    "github_skill_url": "${GITHUB_SKILL_URL}",
    "github_skill_endpoint_ok": ${GITHUB_SKILL_OK},
    "mdns_service": "${MDNS_SERVICE}",
    "mdns_discovered_host": "${MDNS_DISCOVERED}",
    "base_url": "${STAGEDROID_BASE_URL}",
    "live_skill_endpoint_ok": ${LIVE_SKILL_OK},
    "active_skill_reference": "${SKILL_SOURCE_USED}",
    "adb_proxy_port": ${STAGEDROID_PROXY_PORT_VAL},
    "status": ${STATUS_JSON},
    "discovery": ${DISCOVERY_JSON}
  }
}
EOF
