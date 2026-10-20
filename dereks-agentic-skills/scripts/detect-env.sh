#!/usr/bin/env bash
# Probe installed orchestration harnesses, sub-agent CLIs, spec tools, memory daemons,
# and Android device tools, merging with user preferences in ~/.config/dereks-agentic-skills/config.json.

set -euo pipefail

CONFIG_DIR="${DEREKS_AGENTIC_SKILLS_CONFIG_DIR:-${AGENT_ORCHESTRATION_CONFIG_DIR:-${HOME}/.config/dereks-agentic-skills}}"
CONFIG_FILE="${CONFIG_DIR}/config.json"
mkdir -p "${CONFIG_DIR}/memory"

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# 1. Detect Orca or alternative orchestration harnesses
ORCA_BIN=""
if [[ -n "${ORCA_CLI_COMMAND:-}" ]] && has_cmd "${ORCA_CLI_COMMAND}"; then
  ORCA_BIN="${ORCA_CLI_COMMAND}"
elif [[ -n "${ORCA_DEV_REPO_ROOT:-}" ]] && has_cmd "orca-dev"; then
  ORCA_BIN="orca-dev"
elif has_cmd "orca-ide"; then
  ORCA_BIN="orca-ide"
elif has_cmd "orca"; then
  ORCA_BIN="orca"
fi

# 2. Detect available sub-agent CLIs
AGENTS_FOUND=()
for candidate in claude antigravity gemini codex opencode aider cursor; do
  if has_cmd "$candidate"; then
    AGENTS_FOUND+=("\"$candidate\"")
  fi
done
AGENTS_JSON="[$(IFS=,; echo "${AGENTS_FOUND[*]:-}")]"

# 3. Detect Spec tool
SPEC_TOOL="markdown"
if has_cmd "openspec"; then
  SPEC_TOOL="openspec"
fi

# 4. Detect AgentMemory daemon (port 3111) or CLI
MEMORY_TOOL="file-digest"
if curl -fsS --max-time 1 http://localhost:3111/agentmemory/livez >/dev/null 2>&1; then
  MEMORY_TOOL="agentmemory-running"
elif has_cmd "npx"; then
  MEMORY_TOOL="agentmemory-available-via-npx"
fi

# 5. Detect Android & Remote Device tools
DEVICE_TOOLS=()
for dev_cmd in adb scrcpy tailscale state-droid emulator; do
  if has_cmd "$dev_cmd"; then
    DEVICE_TOOLS+=("\"$dev_cmd\"")
  fi
done
DEVICE_TOOLS_JSON="[$(IFS=,; echo "${DEVICE_TOOLS[*]:-}")]"

# 6. Initialize default config if not present
if [[ ! -f "${CONFIG_FILE}" ]]; then
  PREFERRED_ORCHESTRATOR="${ORCA_BIN:-git-worktree}"
  cat <<EOF > "${CONFIG_FILE}"
{
  "preferred_orchestrator": "${PREFERRED_ORCHESTRATOR}",
  "preferred_subagents": ${AGENTS_JSON},
  "preferred_spec_tool": "${SPEC_TOOL}",
  "preferred_memory_tool": "${MEMORY_TOOL}",
  "default_device_serial": "${ANDROID_SERIAL:-}",
  "device_lock_dir": "/tmp"
}
EOF
fi

cat <<EOF
{
  "config_file": "${CONFIG_FILE}",
  "detected": {
    "orca_binary": "${ORCA_BIN}",
    "subagent_clis": ${AGENTS_JSON},
    "spec_tool": "${SPEC_TOOL}",
    "memory_tool": "${MEMORY_TOOL}",
    "device_tools": ${DEVICE_TOOLS_JSON},
    "android_serial_env": "${ANDROID_SERIAL:-}"
  },
  "saved_preferences": $(cat "${CONFIG_FILE}")
}
EOF
