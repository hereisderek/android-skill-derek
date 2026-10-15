# android-skill-derek

Modular Android & engineering agent skills repository with a root `SKILL.md` router that delegates to five self-contained sub-skill folders. Built to be **tool-agnostic**—automatically probing available orchestration harnesses, sub-agent CLIs, spec managers, shared memory services, and Android SDK/device tools while maintaining a long-lived coordinator cache in `~/.config/android-skill-derek/`.

## Repository Structure

```text
android-skill-derek/
├── SKILL.md                                           # Root router skill & SKILL_ROOT / cache resolver
├── README.md                                          # Install, symlink & update documentation
├── .gitignore                                         # Excludes temporary device dumps, screenshots & keystores
├── scripts/
│   └── link-myskills.sh                               # Direct local symlink helper for all installed agents
├── android-design-gallery-and-signing/                # Design language, Component Gallery, Dummy Data & Signing
│   ├── SKILL.md
│   ├── scripts/
│   │   └── check-signing-safety.sh                    # Verifies shared debug keystore & git-ignored release keys
│   └── assets/
│       ├── ComponentGalleryTemplate.kt                # Jetpack Compose themed Component Gallery + Dummy Data
│       └── signing-config.gradle.kts                  # Shared debug key + env-var release signing Kotlin DSL
├── state-droid-remote-device/                         # StageDroid, Physical/Virtual Device Pool, Wake/Unlock & UI Audit
│   ├── SKILL.md
│   ├── scripts/
│   │   ├── device-check.sh                            # Probes StageDroid (/skill, /status, /api/discovery & mDNS), GitHub & ADB
│   │   ├── device-pool.sh                             # Leases StageDroid/physical devices or boots AVDs via Google CLI
│   │   ├── device-wake-unlock.sh                      # Wakes sleeping screens & unlocks with cached passcode
│   │   ├── device-ui-audit.sh                         # Audits resolutions, densities, font scales, cutouts & insets
│   │   └── device-verify-gate.sh                      # Full Coordinator Gate 2 installer, test & UI audit runner
│   └── assets/
│       ├── stagedroid-snapshot.md                     # Snapshot of StageDroid SKILL.md while GitHub repo is private
│       └── device-profile.example.json                # Example device pool & passcode configuration template
├── android-agent-orchestration/                       # Multi-agent orchestration, rebase QA, triage & cleanup
│   ├── SKILL.md
│   ├── scripts/
│   │   └── detect-env.sh                              # Probes Orca, sub-agents, OpenSpec, AgentMemory & Android SDK
│   └── assets/
│       ├── config.example.json                        # Example ~/.config/android-skill-derek/config.json
│       └── worker-task-template.md                    # 6-Point Worker Task-Spec preamble template
├── release-cicd/                                      # Release tagging (v* / beta_*) & CI/CD pipeline policy
│   └── SKILL.md
├── markdown-converter/                                # Document-to-Markdown conversion via uvx markitdown
│   ├── SKILL.md
│   └── .skillfish.json
└── philipp-android-skills/                            # Philipp Lackner Android & KMP Architecture Skills
    ├── SKILL.md                                       # Architecture router for child skills
    ├── android-module-structure/                      # Feature-layered modularization & Gradle conventions
    ├── android-presentation-mvi/                      # MVI State/Action/Event & Root/Screen composables
    ├── android-navigation/                            # Type-safe Navigation Compose routes & graphs
    ├── android-di-koin/                               # Koin dependency injection modules & scoping
    ├── android-data-layer/                            # Repositories, Room, Ktor, DTOs & offline-first
    ├── android-error-handling/                        # Typed Result & DataError handling
    ├── android-compose-components/                    # Reusable Compose UI components & previews
    ├── android-unit-testing/                          # JUnit 5, AssertK & Turbine unit testing
    └── pr-quiz/                                       # GitHub PR reviewer quiz generator
```

## Installation

Install globally with [`npx skills`](https://github.com/vercel-labs/skills) so the canonical copy is stored in `~/.agents/skills/android-skill-derek` and the interactive prompt lets you **Symlink (Recommended)** into your installed coding agents (Claude Code, Google Antigravity, Cursor, Gemini CLI, Codex, Windsurf, OpenCode, etc.):

```bash
# Recommended: GitHub shorthand (uses HTTPS + Git credentials / gh CLI / SSH fallback)
npx skills add hereisderek/android-skill-derek -g

# Or using the full HTTPS URL
npx skills add https://github.com/hereisderek/android-skill-derek -g

# Or using SSH (if you authenticate strictly via SSH keys)
npx skills add git@github.com:hereisderek/android-skill-derek.git -g

# Or link directly from a local clone across ~/.agents/skills, ~/.claude/skills, ~/.codex/skills, ~/.gemini/skills, etc.
./scripts/link-myskills.sh --apply
```

When prompted during `npx skills add`:

1. Select the coding agents you want to link.
2. Choose **Symlink (Recommended)** so each agent points to the single canonical copy in `~/.agents/skills/android-skill-derek`.

## Updating

Because symlinks point back to the canonical global skill directory, updating pulls the latest changes once and updates all linked agents:

```bash
# Update this skill globally
npx skills update android-skill-derek -g

# Or update all global skills
npx skills update -g
```

## Persistent Preferences & Coordinator Cache (`~/.config/android-skill-derek/`)

- `config.json`: Stores your preferred orchestration harness (`orca` or `git-worktree`), sub-agent CLIs, spec/memory tools, and shared debug keystore path.
- `devices.json` (`0600` permissions): Caches per-device unlock passcodes and StageDroid endpoints so `device-wake-unlock.sh` can wake and unlock sleeping test devices automatically.
- `cache/`: Long-lived Coordinator cache holding active device leases (`device-leases.json`), live StageDroid `/skill` downloads (`stagedroid-live-skill.md`), and project architectural digests across sessions.
