---
name: android-skill-derek
description: Router skill for Android and engineering workflows covering (1) Design Language, Shared Component Gallery, Dummy Data & Signing Keys, (2) StageDroid/Physical/Virtual Test Device Pool, Wake/Unlock & Multi-Density/Inset UI Auditing, (3) Multi-Agent Android Orchestration with Rebase Device Testing & Coordinator Triage, (4) Release Tagging (`v*` / `beta_*`) & CI/CD Pipelines, (5) Document-to-Markdown Conversion (`markitdown`), (6) Philipp Lackner Android & KMP Architecture Skills (Module Structure, MVI Presentation, Navigation Compose, Koin DI, Data Layer, Error Handling, Unit Testing, Reusable Components, PR Quiz), and (7) Interaction-Driven Animation & Latest Material Design Motion (1:1 gesture tracking, fling momentum, cross-platform design adaptations). Auto-detects available tools and persists long-lived preferences and cache in ~/.config/android-skill-derek/.
---

# Android & Engineering Skill Router (`android-skill-derek`)

Entry point and router for specialized Android development, device verification, multi-agent orchestration, release CI/CD, and document conversion workflows. Inspect the user's request, resolve `SKILL_ROOT` and the persistent coordinator cache in `~/.config/android-skill-derek/`, and load the matching sub-skill module(s) below.

## When to Use

- Designing or building Android apps with Material Design 3 (or a custom design language), a themed **Shared Component Gallery**, deterministic **Dummy Data**, and safe **Debug/Release Signing Keys**
- Building cross-platform apps (Compose Multiplatform / KMP, Flutter, React Native, Web) where design, theme, icon, and style adapt to respective platform practices (Material Design 3 on Android, HIG/SF Symbols on iOS/macOS, web/desktop conventions)
- Implementing or reviewing gesture-triggered animations (collapsing headers, carousels, bottom sheets, pull to refresh, swipe actions) following the latest version of **Material Design animation/motion** and **interaction-driven animation** (1:1 finger tracking, velocity fling on release, zero jump on touch interruption)
- Discovering, leasing, waking, unlocking (with PIN/passcode), and auditing StageDroid, physical, wireless, or Google CLI virtual (AVD) test devices across screen sizes, densities, cutouts, and system bars
- Orchestrating feature-named sub-agents across isolated git worktrees in **Manual** vs. **Automatic** mode, executing the **Coordinator Cycle Workflow** (`sweep`, `check progress and merge`, `run the cycle`, `/cycle`), assigning scarce test devices, testing rebased branches on device, triaging bugs (fix on the spot vs. send back), and cleaning up worktrees after merge
- Cutting, tagging, or configuring CI/CD for a stable (`v1.2.3`) or beta (`beta_1.2.3`) release with explicit per-tag human approval
- Converting documents, PDFs, Office files, images, audio, or archives into Markdown via `uvx markitdown`
- Architecting, implementing, or reviewing Android & Kotlin Multiplatform (KMP) features following Philipp Lackner's conventions: feature-layered module boundaries, MVI presentation (single State, sealed Action, Channel Event, Root/Screen composables, SavedStateHandle), type-safe Compose Navigation, Koin dependency injection, offline-first data layer (Room, Ktor, DTOs, mappers), typed error handling (Result/DataError), unit tests (JUnit 5 + AssertK + Turbine), reusable Compose components, or GitHub PR reviewer quizzes

## Path & Persistent Cache Resolution

1. **Resolve `SKILL_ROOT`**: Set `SKILL_ROOT` to the directory containing this root `SKILL.md` file (for example, `~/.agents/skills/android-skill-derek` when installed globally via `npx skills add -g`, or `./.agents/skills/android-skill-derek` when installed locally). Always reference sub-skills, scripts, and assets via `$SKILL_ROOT/<sub-skill>/...`.
2. **Maintain Long-Lived Coordinator Cache (`~/.config/android-skill-derek/`)**:
   - Run `bash "$SKILL_ROOT/android-agent-orchestration/scripts/detect-env.sh"` to load user preferences from `~/.config/android-skill-derek/config.json` and auto-detect installed harnesses (`orca`, `claude`, `antigravity`, `gemini`, `codex`, `opencode`), spec tools (`openspec`), memory services (`@agentmemory/agentmemory`), and Android SDK/device tools (`adb`, `emulator`, `avdmanager`, `sdkmanager`, `scrcpy`, `tailscale`).
   - Keep `~/.config/android-skill-derek/cache/`, `devices.json`, and `config.json` persistent across sessions so device passcodes, active leases, live StageDroid `/skill` specs, architectural digests, and tool preferences are remembered long-term.

## Sub-Skill Routing Table

| Sub-Skill Folder | Target File | Helper Scripts | When to Route Here |
| --- | --- | --- | --- |
| `android-design-gallery-and-signing` | `$SKILL_ROOT/android-design-gallery-and-signing/SKILL.md` | `scripts/check-signing-safety.sh` | Setting up Material/custom design tokens, edge-to-edge window insets (status bar, cutout, bottom nav), cross-platform design/theme/icon adaptation, in-app themed **Shared Component Gallery**, deterministic **Dummy Data** fixtures, and shared debug key + env-var release signing |
| `interaction-driven-animation` | `$SKILL_ROOT/interaction-driven-animation/SKILL.md` | — | Making animations that a user triggers by touching, dragging, scrolling, or swiping follow the input 1:1, continue with momentum/fling when released, and stop without jump if re-touched across Compose, SwiftUI, or Web |
| `state-droid-remote-device` | `$SKILL_ROOT/state-droid-remote-device/SKILL.md` | `scripts/device-check.sh`, `scripts/device-pool.sh`, `scripts/device-wake-unlock.sh`, `scripts/device-ui-audit.sh`, `scripts/device-verify-gate.sh` | Resolving StageDroid instructions from official GitHub first, then a server `/skill`, then the local snapshot; discovering devices (`/status`, `/api/discovery` & mDNS `_stagedroid._tcp`), Wireless/USB ADB, or Google CLI virtual devices (`avdmanager`/`emulator`), leasing test devices to sub-agents, waking/unlocking passcode-protected devices, and auditing screen resolutions/densities/cutouts/clipping |
| `android-agent-orchestration` | `$SKILL_ROOT/android-agent-orchestration/SKILL.md` | `scripts/detect-env.sh` | Orchestrating in Manual vs. Auto modes, executing Coordinator Cycle Workflow (`sweep`, `check progress and merge`, `run the cycle`, `/cycle`), naming sub-agents after features/branches, assigning device leases, delegating validation to lower-intelligence Gemini Flash agents (with immediate cleanup on completion), testing rebases on device, fixing simple bugs on the spot vs. sending back to sub-agents, and managing keep-alive windows |
| `release-cicd` | `$SKILL_ROOT/release-cicd/SKILL.md` | — | Cutting or tagging any release (`v<major>.<minor>.<patch>` stable or `beta_<major>.<minor>.<patch>` beta, requiring explicit per-tag user approval) or configuring/fixing release CI/CD pipelines (build, test, sign, package, release notes, Play Store / GitHub Release publishing) |
| `markdown-converter` | `$SKILL_ROOT/markdown-converter/SKILL.md` | — | Converting PDF, Word (`.docx`), PowerPoint (`.pptx`), Excel (`.xlsx`), HTML, CSV, images (OCR), audio, ZIPs, or EPubs to Markdown using `uvx markitdown` |
| `philipp-android-skills` (Router) | `$SKILL_ROOT/philipp-android-skills/SKILL.md` | — | Master router for opinionated Android and Kotlin Multiplatform architecture conventions across all layers |
| `philipp-android-skills/android-module-structure` | `$SKILL_ROOT/philipp-android-skills/android-module-structure/SKILL.md` | — | Project setup, Gradle conventions, feature-layered modularization, version catalogs, and dependency rules |
| `philipp-android-skills/android-presentation-mvi` | `$SKILL_ROOT/philipp-android-skills/android-presentation-mvi/SKILL.md` | — | MVI presentation pattern: single `State`, sealed `Action`, one-time `Event` side-effects via `Channel`, ViewModel wiring, Root/Screen composables, `UiText`, and `SavedStateHandle` |
| `philipp-android-skills/android-navigation` | `$SKILL_ROOT/philipp-android-skills/android-navigation/SKILL.md` | — | Type-safe Navigation Compose using `@Serializable` routes, per-feature nav graphs, and cross-feature navigation callbacks |
| `philipp-android-skills/android-di-koin` | `$SKILL_ROOT/philipp-android-skills/android-di-koin/SKILL.md` | — | Koin dependency injection: feature-layer modules, `single`/`viewModel`/`factory` scoping, `:app` wiring, and `koinViewModel()` in composables |
| `philipp-android-skills/android-data-layer` | `$SKILL_ROOT/philipp-android-skills/android-data-layer/SKILL.md` | — | Repository/data-source design, DTOs, Room entities/DAOs, Ktor `HttpClient`, safe-call helpers, token storage, and offline-first caching |
| `philipp-android-skills/android-error-handling` | `$SKILL_ROOT/philipp-android-skills/android-error-handling/SKILL.md` | — | Typed `Result` values, `DataError`, domain errors, and mapping success or failure across data and presentation layers |
| `philipp-android-skills/android-compose-components` | `$SKILL_ROOT/philipp-android-skills/android-compose-components/SKILL.md` | — | Reusable extracted Compose components, design-system UI building blocks, synchronized animations (continuous & unified fling), and `@Preview` setups |
| `philipp-android-skills/android-unit-testing` | `$SKILL_ROOT/philipp-android-skills/android-unit-testing/SKILL.md` | — | In-process tests for ViewModels, use cases, reducers, and mappers using JUnit 5 + AssertK + Turbine + fake repositories |
| `philipp-android-skills/pr-quiz` | `$SKILL_ROOT/philipp-android-skills/pr-quiz/SKILL.md` | — | Generating and maintaining interactive reviewer quizzes for GitHub pull requests |

## Routing Steps

1. Resolve `SKILL_ROOT` to the directory where this root `SKILL.md` resides.
2. Identify which domain(s) in the routing table above match the user's goal.
3. Read the target sub-skill `SKILL.md` file(s) before executing any helper scripts or workflows.
