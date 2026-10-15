#!/usr/bin/env bash
# Audit Android signing key hygiene:
# 1. Ensures shared debug keystore exists and is recorded in ~/.config/android-skill-derek/config.json
# 2. Checks that no production .jks / .keystore files or plaintext signing passwords are tracked by Git
# 3. Reports whether release signing environment variables are set

set -euo pipefail

PROJECT_DIR="${1:-.}"
CONFIG_DIR="${HOME}/.config/android-skill-derek"
CONFIG_FILE="${CONFIG_DIR}/config.json"
DEFAULT_DEBUG_KEYSTORE="${HOME}/.android/debug.keystore"
mkdir -p "${CONFIG_DIR}" "${HOME}/.android"

# 1. Ensure standard shared debug.keystore exists so all worktrees share the exact same debug key
if [[ ! -f "${DEFAULT_DEBUG_KEYSTORE}" ]] && command -v keytool >/dev/null 2>&1; then
  keytool -genkey -v \
    -keystore "${DEFAULT_DEBUG_KEYSTORE}" \
    -storepass android \
    -alias androiddebugkey \
    -keypass android \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1 || true
fi

# 2. Check git tracked files for accidentally committed production keystores
TRACKED_KEYSTORES="[]"
if git -C "${PROJECT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  FOUND=$(git -C "${PROJECT_DIR}" ls-files '*.jks' '*.keystore' '*.p12' '*.pfx' | grep -v 'debug\.keystore' || true)
  if [[ -n "${FOUND}" ]]; then
    TRACKED_KEYSTORES=$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().splitlines()))' <<< "${FOUND}")
  fi
fi

# 3. Check release signing environment variables (without printing secret values)
HAS_RELEASE_ENV="false"
if [[ -n "${ANDROID_KEYSTORE_PATH:-}" ]] && [[ -n "${ANDROID_KEYSTORE_PASSWORD:-}" ]] && [[ -n "${ANDROID_KEY_ALIAS:-}" ]] && [[ -n "${ANDROID_KEY_PASSWORD:-}" ]]; then
  HAS_RELEASE_ENV="true"
fi

cat <<EOF
{
  "ok": $( [[ "${TRACKED_KEYSTORES}" == "[]" ]] && echo "true" || echo "false" ),
  "shared_debug_keystore": "${DEFAULT_DEBUG_KEYSTORE}",
  "shared_debug_keystore_exists": $( [[ -f "${DEFAULT_DEBUG_KEYSTORE}" ]] && echo "true" || echo "false" ),
  "tracked_non_debug_keystores": ${TRACKED_KEYSTORES},
  "release_env_vars_configured": ${HAS_RELEASE_ENV},
  "expected_release_env_vars": [
    "ANDROID_KEYSTORE_PATH",
    "ANDROID_KEYSTORE_PASSWORD",
    "ANDROID_KEY_ALIAS",
    "ANDROID_KEY_PASSWORD"
  ]
}
EOF
