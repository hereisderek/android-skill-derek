#!/usr/bin/env bash

# Link each folder (or the root skill folder) into every installed agent's skill folder.
# Run without arguments to preview. Pass --apply to create the symlinks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SOURCE="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="${MY_SKILLS_DIR:-${DEFAULT_SOURCE}}"
MODE="dry-run"

case "${1:-}" in
    "") ;;
    --apply) MODE="apply" ;;
    --help|-h)
        printf 'Usage: %s [--apply]\n' "$0"
        printf 'Source: %s (override with MY_SKILLS_DIR)\n' "$SOURCE_DIR"
        exit 0
        ;;
    *)
        printf 'Unknown option: %s\n' "$1" >&2
        exit 2
        ;;
esac

if [[ ! -d "$SOURCE_DIR" ]]; then
    printf 'Source directory does not exist: %s\n' "$SOURCE_DIR" >&2
    exit 1
fi

shopt -s nullglob
SKILLS=()
# If SOURCE_DIR itself contains SKILL.md (router layout), link SOURCE_DIR; also support sub-skill folders
if [[ -f "$SOURCE_DIR/SKILL.md" ]]; then
    SKILLS+=("$SOURCE_DIR")
else
    for candidate in "$SOURCE_DIR"/*/; do
        candidate="${candidate%/}"
        [[ -f "$candidate/SKILL.md" ]] && SKILLS+=("$candidate")
    done
fi

if (( ${#SKILLS[@]} == 0 )); then
    printf 'No skill folders found in %s\n' "$SOURCE_DIR"
    exit 0
fi

DESTINATIONS=(
    "$HOME/.agents/skills"
    "$HOME/.claude/skills"
    "$HOME/.codex/skills"
    "$HOME/.gemini/skills"
    "$HOME/.config/opencode/skills"
    "$HOME/.pi/agent/skills"
)

for destination in "${DESTINATIONS[@]}"; do
    if [[ ! -d "$destination" ]]; then
        printf 'Skipping missing agent skill directory: %s\n' "$destination"
        continue
    fi

    printf '\n%s\n' "$destination"
    for source in "${SKILLS[@]}"; do
        target="$destination/${source##*/}"

        if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
            printf '  exists: %s\n' "$target"
        elif [[ -e "$target" || -L "$target" ]]; then
            printf '  conflict (unchanged): %s\n' "$target" >&2
        elif [[ "$MODE" == "apply" ]]; then
            ln -s "$source" "$target"
            printf '  linked: %s -> %s\n' "$target" "$source"
        else
            printf '  would link: %s -> %s\n' "$target" "$source"
        fi
    done
done

if [[ "$MODE" == "dry-run" ]]; then
    printf '\nDry run only. Re-run with --apply to create symlinks.\n'
fi
