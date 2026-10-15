---
name: android-agent-orchestration
description: Orchestrate multi-agent Android and full-stack development workflows using descriptive feature/branch sub-agent naming, test device pool leasing (physical or Google CLI virtual AVDs), rebase device testing, fix-on-the-spot vs. send-back coordinator triage, layered UI/API validation, and long-lived local caching in ~/.config/android-skill-derek/.
---

# Android Agent Orchestration (`android-agent-orchestration`)

Coordinate complex Android (and companion backend) engineering across parallel sub-agents without file collisions, device contention, or unverified merges. Pairs a **tool-agnostic orchestration workflow** with dedicated command references for **Orca**, **OpenSpec**, and **AgentMemory**.

## When to Use

- Coordinating multi-module Android features, Component Gallery/theme setup, Gradle foundation work, or companion backend services across sub-agents
- Naming, spawning, and managing isolated git-worktree sub-agents
- Assigning scarce physical or virtual (AVD) test devices from a pool to sub-agents and testing rebased branches on device
- Performing Coordinator verification, triaging bugs (fix on the spot vs. send back to the original sub-agent), and cleaning up worktrees and sub-agents after merge

## 1. Phase 0: Pre-Flight Environment, Long-Lived Cache & Device Pool Check

### 1.1 Long-Lived Coordinator Local Cache (`~/.config/android-skill-derek/`)

As Coordinator, maintain a persistent local cache in `~/.config/android-skill-derek/` (`config.json`, `devices.json`, and `cache/`) with a long retention window across runs:

- **Never wipe cached state prematurely**: Preserve discovered tool preferences, StageDroid/mDNS endpoints, device passcodes, device lease registries (`cache/device-leases.json`), architectural digests (`cache/<project>-digest.md`), and local Gradle build caches (`--build-cache`) so subsequent waves and sessions start instantaneously.
- Run the environment detector at the start of a session:

  ```bash
  bash "$SKILL_ROOT/android-agent-orchestration/scripts/detect-env.sh"
  ```

### 1.2 Tool Capability Matrix & Fallbacks

| Capability | Primary / Specialized Tool | Generic Alternatives & Fallbacks |
| --- | --- | --- |
| **Orchestration Harness** | **Orca** (`$ORCA_CLI_COMMAND`, `orca-dev`, `orca-ide`, `orca`) | Native sub-agent tools (Claude Code `Task` subagents, Antigravity subagents), `git worktree` + background CLI (`claude`, `gemini`, `codex`, `opencode`) |
| **Sub-Agent Runtimes** | Choose the available model/runtime that best fits the task | `claude`, `antigravity` / `gemini`, `codex`, `opencode`, `aider`, `cursor`, or sequential worktree execution |
| **Spec & Change Tracking** | **OpenSpec** (`openspec` CLI + `/opsx:*` workflows) | Repository markdown specs (`docs/SPEC.md`, `AGENTS.md`, `tasks.md`) |
| **Shared Agent Memory** | **AgentMemory** (`@agentmemory/agentmemory`, port `3111`, MCP `memory_*`) | Persistent digest in `~/.config/android-skill-derek/cache/<project>-digest.md` and `.agents/memory/architecture-digest.md` |
| **Test Device Pool** | **StageDroid / Physical ADB + Google Android CLI AVDs** (`$SKILL_ROOT/state-droid-remote-device/SKILL.md`) | `sdkmanager`, `avdmanager`, `emulator -avd` virtual devices when physical devices are scarce |
| **Design, Gallery & Signing** | **Design, Gallery, Dummy Data & Signing** (`$SKILL_ROOT/android-design-gallery-and-signing/SKILL.md`) | Shared `~/.android/debug.keystore` + env-var release signing (`ANDROID_KEYSTORE_*`) |

### 1.3 Test Device Pool Allocation & Sub-Agent Device Assignment

Test devices are often scarce during parallel development. The Coordinator manages the pool of physical devices (USB, Wireless ADB, StageDroid) and virtual devices (provisioned via Google's Android command-line tools `sdkmanager`, `avdmanager`, `emulator`):

1. **Inspect the Device Pool**:

   ```bash
   bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" list
   ```

2. **Assigning Devices to Sub-Agents vs. Coordinator**:
   - **If multiple devices or AVDs are available**: When a sub-agent needs a test device to verify its work, lease a dedicated device serial (`ANDROID_SERIAL`) for that sub-agent via `device-pool.sh lease --owner "<subagent-name>"` (which automatically boots a virtual device via `emulator -avd` if physical devices are taken) and pass `ANDROID_SERIAL=<leased_serial>` in the sub-agent's task prompt.
   - **If only a single test device exists**: Sub-agents run JVM unit tests (`./gradlew testDebugUnitTest`), Robolectric/Compose JVM tests, and `./gradlew lintDebug` in their worktrees, or request a short serialized lease through the Coordinator; the Coordinator serializes all on-device installs, UI play-testing, and rebase testing on that single device.

## 2. Sub-Agent Dispatch Protocol

## 2.1 Choose the Right Runtime and Advisor

- Do not default workers to the Coordinator's runtime. Select an available agent and model based on the task's complexity, tool access, Android expertise, cost, and expected duration.
- For a long, multi-step, ambiguous, repeatedly failing, or completion-critical Claude Code task, use the experimental [Advisor](https://code.claude.com/docs/en/advisor) when the account, main model, and billing setup support it. Pair a cost-effective main model with an advisor that is at least as capable; do not enable it for simple, direct work where the additional consultation has little value.
- Record the chosen runtime/model and the reason in the dispatch. If Advisor is unavailable or unsupported, continue with an independent review or validation worker when warranted.

## 2.2 Timeboxed Dispatch and Progress Protocol

Every delegated task has a bounded, two-way estimate. Keep simple, localized validation or fixes with the Coordinator; delegate only work whose complexity benefits from isolation or a second model.

1. **Coordinator dispatch**: state the requested outcome, the expected time range, a checkpoint cadence for work exceeding 30 minutes, and the handoff requirements below.
2. **Worker assessment before implementation**: inspect the task and reply to the Coordinator with its own estimate, assumptions, milestones, and any likely blocker *before* changing code. It must revise that estimate promptly if scope changes.
3. **Coordinator follow-up**: at the worker's estimate plus a reasonable leeway (normally 25%, at least 10 minutes), request a concise status update. Ask earlier if the task misses a stated milestone or its device lease is blocking another worker. Do not let a worker silently run indefinitely.
4. **Stuck work**: after two missed updates, a repeated blocker, or an estimate materially exceeded without a recovery plan, pause or redirect the task, preserve its worktree/logs, and decide whether to narrow, reassign, or finish the smallest safe part directly.
5. **Completion report**: include estimate versus actual duration, milestones completed, files changed, commands/tests run and results, deployed package/device serial when applicable, remaining risks, and a clear `ready for coordinator validation` status.

### 2.3 Descriptive Sub-Agent Naming Rule

Always name every sub-agent and its git worktree descriptively after the **feature it is developing** or its **git branch name** so the user immediately knows what each agent is doing:

- **Good Names**: `feat-component-gallery`, `feat-events-countdown`, `feat-auth-live-sharing`, `fix-pin-session-token`, `qa-rebase-events`
- **Forbidden Names**: Never use opaque labels like `worker-1`, `agent-2`, `subagent-a`, or `temp-worker`.

When creating worktrees or starting Orca workers, keep the branch name, worktree folder, and worker `--name` aligned:

```bash
# Example: feature-named worktree and sub-agent
ORCA orchestration worker-start \
  --agent claude \
  --model claude-sonnet-4-6 \
  --effort medium \
  --worktree new-child \
  --name "feat-events-countdown" \
  --prompt "<6-point task spec>"
```

## 3. Non-Blocking Parallel Wave Plan (DAG)

1. **Track A (Independent Companion / Backend Services — Immediate Parallel Track)**:
   - Self-contained backend or cloud worker directories (`services/*`, `server/*`) run in parallel with Android Wave 0.
2. **Track B — Wave 0 (Sequential Gate: Foundation, Theme, Component Gallery, Dummy Data & Signing)**:
   - Load `$SKILL_ROOT/android-design-gallery-and-signing/SKILL.md`.
   - Configure consistent shared debug signing (`~/.android/debug.keystore`) and environment-variable-only release signing (`ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`).
   - Implement the design language tokens (Material 3 or custom `DESIGN_SYSTEM.md`), window inset handling, deterministic **Dummy Data Fixtures**, and the in-app **Shared Component Gallery** screen.
   - Verify on the test device, then merge Wave 0 into the base branch before launching Wave 1.
3. **Track B — Wave 1+ (Concurrent Feature Fan-Out — Cap at 4 Named Workers)**:
   - Spawn up to 4 feature-named sub-agents in isolated child worktrees. Each feature sub-agent must register any new shared UI components in the **Component Gallery** and provide dummy data fixtures for its screens.

## 4. Worker Handoff Must Be Test-Ready

Before a worker hands off a build deliverable, it must make the current branch ready for Coordinator validation:

- Run the relevant fast checks and the assigned test suite.
- If it has a leased test device, build, install, and launch the debug app on that device; leave the intended screen or reproducible entry path ready for testing. Report the package, serial, build variant, and launch command/result. Do not release the lease until the Coordinator acknowledges the handoff or the agreed lease window ends.
- If no device was assigned, produce the installable artifact and exact install/launch steps, then state that device validation remains with the Coordinator. Do not claim on-device validation was performed.

## 5. Layered Results Validation (UI Play-Testing + Automated UI & API/Logic Tests)

Every feature must be validated across three complementary layers:

1. **API & Domain Logic Layer (Unit Tests & Library/Network Requests)**:
   - Write comprehensive unit and integration tests for all repositories, ViewModels, use cases, domain calculators, and parsers (JUnit, Coroutines Test, Turbine, MockWebServer/Ktor MockEngine, or Vitest).
   - Execute real or mocked library/API requests to verify wire serialization, auth headers, error handling, and edge cases.
2. **Automated UI Test Layer**:
   - Write automated Compose UI / Espresso instrumentation tests covering user interactions, state transitions (Populated, Empty, Error, Loading using dummy data fixtures), and navigation.
3. **Interactive On-Device Play-Testing & Multi-Screen Audit (Coordinator)**:
   - Wake and unlock the test device (`device-wake-unlock.sh`), install the debug APK, launch the app and the **Shared Component Gallery**, and actively **play around with the UI** (tap buttons, toggle Light/Dark theme, switch dummy data scenarios, scroll lists, test dialogs and back navigation).
   - Run `device-ui-audit.sh` to verify different screen sizes, resolutions, and densities (`wm size`, `wm density`, `font_scale 1.3`), checking that no text or edges are cut off and that the **status bar**, **display cutout (notch/pinhole)**, and **bottom navigation bar** insets are respected.

## 6. Coordinator Rebase Testing, Bug Triage (Fix-on-the-Spot vs. Send-Back) & Cleanup

All final verification is performed by **you (the Coordinator)** before any code is merged into the main branch:

### Step 1: Rebase onto Target Branch & Test the Rebase on Device

Before merging a worker's branch, rebase the worker's worktree branch onto the latest target branch (`main` / `develop`) so it incorporates any previously merged sibling features:

```bash
git -C "<worker_worktree>" rebase main
```

Then run the full test suite (`./gradlew lintDebug testDebugUnitTest`) AND install/test the **rebased build on the test device** (`device-verify-gate.sh --run-ui-audit`) to guarantee the rebase introduced zero build, runtime, or visual regressions.

### Step 2: Coordinator Bug Triage — Fix on the Spot vs. Send Back to Sub-Agent

When Coordinator testing (unit tests, rebase check, interactive device play-testing, or UI inset/density audit) uncovers an issue:

- **Simple / Localized Issue -> Fix on the Spot**:
  - If the defect is small, clear, and localized (for example: a missing window inset modifier, a minor padding or text-overflow tweak, a simple rebase conflict, a missing import, or a small test assertion fix), **fix it directly on the spot** as Coordinator, re-run verification on the test device, and proceed.
- **Complex / Multi-File / Architectural Issue -> Send Back to Original Sub-Agent**:
  - If the defect involves broken business logic, missing feature requirements, failing multi-class flows, or missing test suites, **do not merge**. Dispatch a separate, lower-cost validation worker to reproduce and scope the issue. Give it permission to communicate directly with the implementing worker; they should share exact failures, logs, screenshots, and minimal reproduction steps. The implementing worker owns the repair and re-submission unless the Coordinator explicitly reassigns it.
  - After the repair, the validation worker re-runs the agreed checks and reports to the Coordinator using the completion protocol: result, evidence, actual duration, residual risk, and whether the branch is ready to merge. The Coordinator retains the final merge decision.

### Step 3: Post-Pass Merge & Complete Cleanup

Once all tests and on-device rebase checks pass:

1. **Merge the Branch**: Merge the verified worker branch cleanly into the base branch.
2. **Release Device Lease**:

   ```bash
   bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" release --owner "<subagent-name>"
   ```

3. **Terminate / Release the Sub-Agent & Clean Up Worktree**:
   - **If using Orca**:

     ```bash
     ORCA orchestration worker-release --dispatch <dispatch_id> --json
     ```

   - **If using Git Worktrees directly**:

     ```bash
     git worktree remove "<worker_worktree>"
     git branch -d "<worker_branch>"
     ```

   - Confirm zero leaked worker terminals or stale worktrees remain (`ORCA orchestration worker-list --run <run_id> --terminal-state reclaimable --json` and `git worktree list`).

## Directory Layout

- `SKILL.md`: Orchestration workflow, sub-agent naming, device leasing, rebase testing, triage rules, and cleanup protocol
- `scripts/detect-env.sh`: Probes installed harnesses, spec/memory tools, and device CLIs, updating `~/.config/android-skill-derek/config.json`
- `assets/worker-task-template.md`: 6-Point Worker Task-Spec preamble template (including Component Gallery, Dummy Data, and Signing rules)
- `assets/config.example.json`: Example `~/.config/android-skill-derek/config.json` with long-lived cache settings
