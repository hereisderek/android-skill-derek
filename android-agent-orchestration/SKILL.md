---
name: android-agent-orchestration
description: Orchestrate multi-agent Android and full-stack development workflows using descriptive feature/branch sub-agent naming, test device pool leasing (physical or Google CLI virtual AVDs), rebase device testing, fix-on-the-spot vs. send-back coordinator triage, layered UI/API validation, and long-lived local caching in ~/.config/android-skill-derek/.
---

# Android Agent Orchestration (`android-agent-orchestration`)

Coordinate complex Android (and companion backend) engineering across parallel sub-agents without file collisions, device contention, or unverified merges. Pairs a **tool-agnostic orchestration workflow** with dedicated command references for **Orca**, **OpenSpec**, and **AgentMemory**.

## When to Use

- Coordinating multi-module Android features, Component Gallery/theme setup, Gradle foundation work, or companion backend services across sub-agents
- Operating in **Manual Mode** (active user review for UI/UX changes, deployment notifications) vs. **Automatic Mode** (40-min inactivity fallback, 20-sec user opt-in pause during auto tests)
- Running the **Coordinator Cycle Workflow** (`sweep`, `check progress and merge`, `run the cycle`, `/cycle`) to drain inbox messages, inspect workers, validate mobile/backend tasks, merge cleanly, run host smoke tests, and execute complete cleanup
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

### 1.3 Test Device Pool Allocation, Querying & Exclusive Lock Protocol

Test devices are often scarce during parallel development. The Coordinator and sub-agents manage device access across physical devices (USB, Wireless ADB, StageDroid) and virtual devices (provisioned via Google's Android command-line tools `sdkmanager`, `avdmanager`, `emulator`):

1. **Device Querying & Test Device Definition**:
   - Any agent (Coordinator or sub-agent) can query currently connected devices at any time via `bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" list` or `adb devices`.
   - **Scope of Test Devices**: Any connected device is considered a test device by default unless the user explicitly instructs otherwise. A direct instruction from the user strictly takes precedence over this default.
   - **Coordinator Registry**: The Coordinator must keep and maintain an active list of available test devices, their connection status, and current lock holders.

2. **Assignment vs. Self-Service Lock Request**:
   - **Coordinator Assignment (Standard)**: Usually, the Coordinator passes designated test device(s) (`ANDROID_SERIAL=<leased_serial>`) to the sub-agent in its task dispatch.
   - **Sub-Agent Self-Service Lock (Fallback)**: If the Coordinator omitted device information from the task dispatch and on-device validation is needed, a sub-agent is authorized to query available devices and request an exclusive lock on any available connected device directly via `device-pool.sh lease --owner "<subagent-name>"`.

3. **Exclusive Locking & Active-Testing-Only Constraint**:
   - **Exclusive Single-Use Claim**: When a device is being actively used, either by the Coordinator or a sub-agent, it is claimed exclusively for that single use. No two agents may run commands or tests against the same device concurrently.
   - **Active Testing Only (No Development Holding)**: No agent should hold a device lock longer than needed. Locks are reserved strictly for **active testing and validation** (installing APKs, running automated UI/instrumentation tests, capturing screenshots, executing audits). Devices must **never be locked during code development or writing**. As soon as active tests conclude, release the lock.

4. **Lock Handoff & Rejection Lifecycle**:
   - **Handoff with Deliverables**: When work is delivered from a sub-agent to the Coordinator, the device lock is handed in along with the deliverable (`device-pool.sh transfer --owner "<subagent-name>" --to "coordinator"`).
   - **Return with Rejection**: If work is rejected for improvement/fixes and sent back to the sub-agent, the device lock is handed back along with the task (`device-pool.sh transfer --owner "coordinator" --to "<subagent-name>"`).
   - **Single-Device Fallback**: If only a single device exists and another worker needs testing, workers run unit tests (`./gradlew testDebugUnitTest`), Robolectric/Compose JVM tests, and `./gradlew lintDebug` locally and serialize on-device access.

### 1.4 Coordinator Operating Modes: Manual vs. Automatic Mode

The Coordinator operates under one of two operating modes governing validation, merge gating, and worker lifecycle:

1. **Manual Mode (Default on Launch)**:
   - The user is actively viewing and approving changes.
   - For every piece of work submitted by a sub-agent, **manual user review is required in addition to automatic validation**, whenever **design, website UI, or app UI/UX changes** are involved (treated with identical manual review requirements across app and web).
   - In manual mode, the worker must have changes deployed and explicitly notify the Coordinator that tests are ready (providing accessible links, preview URLs, local ports, or test device serials where suitable) for manual testing.
   - **Pre-Review Detailed Report**: Before prompting the user for manual testing/approval, the Coordinator must display a comprehensive test briefing (what was changed, expected behavior, what to test for, and credentials/test prerequisites).
   - **Keep-Alive Grace Period (20 Minutes for Feature Workers)**: Feature sub-agents and their worktrees are kept alive for **20 minutes** after submission/merge consideration for any potential changes or follow-up tweaks. *(Note: Test/validation workers do not enter keep-alive; they clean up and close immediately once done).*
   - **User Feedback Forwarding**: Any user feedback on a specific piece of work received while the agent is alive is forwarded directly back to that sub-agent.
   - **API Changes Exemption**: Unless specifically instructed otherwise by the user, API changes only require automated tests (no manual review/testing gate needed).

2. **Automatic Mode**:
   - Automated validation runs and accepts completed tasks without requiring manual user review gates.
   - **Detailed Report Right Before the 2-Min Wait**: When sub-agent work is received, *right before entering the 2-minute wait*, the Coordinator must display a detailed report covering:
     1. **What was changed**: Specific files, components, UI layouts, APIs, routes, or schema migrations modified.
     2. **Expected behavior**: Intended user flow, UI states, animations, performance characteristics, and visual outcomes.
     3. **What to test for**: Specific test paths, edge cases, interactions to verify, and verification criteria.
     4. **Credentials & Test Prerequisites**: Any credentials, test accounts, mock tokens, API keys, accessible preview links/ports, or test device serials needed to carry out testing.
   - **One-Time 2-Minute Wait Per Delivered Job (Never Looped)**:
     - While running automated tests, the Coordinator triggers the 2-minute wait (120 seconds) **strictly once** after a worker's job has completed and delivered waiting for verification.
     - **Do not keep running the wait in a loop.** It must never be repeated or polled cyclically for the same job.
     - **Auto-Advance on No Response**: If the user has not responded after the 2-minute window and automated tests pass, the Coordinator considers that job accepted, proceeds with merge/cleanup, and **immediately continues with the next job**.
   - **Fleet Completion to Idle (No More Wait)**:
     - The Coordinator repeats this single one-time verification wait for subsequent worker jobs as they deliver.
     - Once **all jobs** have completed and been verified, the Coordinator transitions immediately to **idle** state—**no more waiting, no polling loops**.
   - **Keep-Alive Grace Period (10 Minutes for Feature Workers)**: Feature sub-agents and their worktrees are kept alive for **10 minutes** after submission/acceptance for any potential follow-up changes. *(Note: Test/validation workers clean up and close immediately once done).*
   - **User Feedback Forwarding**: If the user provides feedback on a specific work during the 10-minute window, forward it directly back to that sub-agent.

3. **Inactivity Timeout & Initial Mode Selection**:
   - **Initial Prompt**: When the user first enters orchestration mode, the Coordinator can ask whether to run in manual or automatic mode.
   - **Default**: Launch defaults to **Manual Mode**.
   - **40-Minute Timeout**: If the user has not been interactive for **40 minutes**, the Coordinator automatically switches to **Automatic Mode**.

## 2. Sub-Agent Dispatch Protocol

## 2.1 Model Selection, Availability & Dynamic Quota Routing

> **Precedence Rule**: The following model routing rules are only suitable when the respective models are available. **A direct instruction from the user strictly takes precedence over this default routing.**

### 2.1.1 Model Selection by Task Complexity
- **Harder Tasks & Design Tasks**:
  - Use **Claude** (`--agent claude` or Antigravity's Claude model) for high-complexity engineering challenges, complex algorithms/concurrency, and **any task relating to design** (UI/UX layouts, Compose styling tokens, design systems, and visual fidelity).
  - **Antigravity Claude**: Antigravity also has a small allocation of Claude models; use it when suitable for harder tasks or design work.
- **Smaller & Easier Tasks**:
  - Use **Antigravity Flash** (`--agent antigravity --model flash` or `flash_lite`) for simple, lightweight, or highly deterministic tasks (e.g., small bug fixes, boilerplate data classes, straightforward refactors, doc updates).
- **Antigravity Argon (Sonnet-Tier Equivalent)**:
  - Antigravity **Argon** is treated as equivalent to **Sonnet** (`--agent antigravity --model argon`). Use it for mid-to-high complexity Android implementation tasks.
- **Effort Constraint**:
  - **Do NOT use high effort** (`--effort high` is strictly avoided).
  - Default to `--effort medium` for standard or complex tasks, and `--effort low` for fast, lightweight tasks.

### 2.1.2 Quota Depletion ("Dry") & Automatic Model Switching
- **Report Quota Dry**: When a model's usage/quota runs dry (rate limited, 429 quota exhaustion, capacity limit, or token budget exhausted), the sub-agent or Coordinator must report the exhaustion immediately (e.g., `[QUOTA_DRY] Model <model_name> usage dry`).
- **Automatic Fallback Switching**: The Coordinator must **automatically switch to the next suitable and available model** in the fallback chain without stalling work:
  - **Fallback Chain for Harder / Design Tasks**:
    1. Primary: Claude (`--agent claude --model claude-sonnet-4-6 --effort medium`)
    2. Secondary: Antigravity Claude (`--agent antigravity --model claude --effort medium`)
    3. Tertiary: Antigravity Argon (`--agent antigravity --model argon --effort medium`, Sonnet-tier equivalent)
    4. Fallback: Antigravity Pro (`--agent antigravity --model pro --effort medium`)
  - **Fallback Chain for Smaller / Easier Tasks**:
    1. Primary: Antigravity Flash (`--agent antigravity --model flash`)
    2. Secondary: Antigravity Flash Lite (`--agent antigravity --model flash_lite`)
    3. Fallback: Antigravity Argon (`--agent antigravity --model argon --effort low`) or standard lightweight model
- **Advisor for Claude Tasks**: For a long, multi-step, ambiguous, or completion-critical Claude Code task, use the experimental [Advisor](https://code.claude.com/docs/en/advisor) when the account, main model, and billing setup support it. Pair a cost-effective main model with an advisor that is at least as capable. Record the chosen runtime/model and the reason in the dispatch.

### 2.1.3 Validation Agent Delegation & Immediate Teardown Discipline
- **Coordinator Does Not Validate Directly**: Unless the test or validation task is **super easy and straightforward** (such as running a single trivial unit test or verifying a 1-line typo fix), the Coordinator does **not** perform validation itself.
- **Lower-Intelligence Validation Agent**: The Coordinator dispatches a lower-intelligence agent to run the validation, execute test suites, perform on-device play-testing/audits, verify logs/screenshots, and report back:
  - **Model Specification**: Currently use **Gemini latest Flash model with low/medium effort** (`--agent antigravity --model flash --effort low` or `--effort medium`, or `--agent gemini --model gemini-2.5-flash`).
- **Immediate Cleanup on Completion (No Keep-Alive)**:
  - Unlike feature-authoring workers (which remain alive for 10 or 20 minutes for follow-up adjustments), **any test/validation worker or sub-agent, once its job is done and results are reported, must just clean up and close immediately**.
  - Immediate teardown sequence:
    1. Release any claimed device lock back to the pool (`bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" release --owner "<validation-agent-name>"`).
    2. Release worker dispatch (`orca orchestration worker-release --dispatch <id>`).
    3. Close worker terminal (`orca terminal close --terminal <handle> --tab`).
    4. Terminate any orphaned background processes in the validation worktree.
    5. Remove the validation worktree and branch (`wt remove <branch>`).

## 2.2 Timeboxed Dispatch and Progress Protocol

Every delegated task has a bounded, two-way estimate. Keep only super easy, straightforward validation or localized trivial fixes with the Coordinator; delegate all other validation (to Gemini Flash) and feature development (to suitable feature agents) to sub-agents.

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
- **Design, Website UI & App UI/UX Changes & Deployment Notification**:
  - In **Manual Mode**, whenever design, website UI, or app UI/UX changes are involved, the worker must deploy the changes (to the leased test device or local preview server) and explicitly notify the Coordinator that tests are ready (providing accessible preview links/ports or test device serials) for manual user testing.
  - In **Auto Mode**, deploy and prepare reproducible entry points for automated test execution.
- **Post-Submission Keep-Alive & Feedback**:
  - Sub-agents remain alive post-submission (**20 minutes in Manual Mode**, **10 minutes in Auto Mode**) for potential revisions.
  - User feedback on a specific work is forwarded directly back to that sub-agent while it remains alive.
- **Test Device Lock Handoff & Active-Testing-Only Constraint**:
  - The device lock must **only be claimed during active testing/validation**, never during feature development.
  - If a device was leased, build, install, and launch the debug app on that device; leave the intended screen or reproducible entry path ready for testing. Report package name, serial, build variant, and launch command/result.
  - Hand the device lock over to the Coordinator upon submission (`bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" transfer --owner "<subagent-name>" --to "coordinator"`).
- If no device was assigned, produce the installable artifact and exact install/launch steps, then state that device validation remains with the Coordinator. Do not claim on-device validation was performed.
- *API changes only require automated tests unless specifically instructed otherwise by the user.*

## 5. Layered Results Validation (UI Play-Testing + Automated UI & API/Logic Tests)

Every feature must be validated across three complementary layers:

1. **API & Domain Logic Layer (Unit Tests & Library/Network Requests)**:
   - Write comprehensive unit and integration tests for all repositories, ViewModels, use cases, domain calculators, and parsers (JUnit, Coroutines Test, Turbine, MockWebServer/Ktor MockEngine, or Vitest).
   - Execute real or mocked library/API requests to verify wire serialization, auth headers, error handling, and edge cases.
2. **Automated UI Test Layer**:
   - Write automated Compose UI / Espresso instrumentation tests covering user interactions, state transitions (Populated, Empty, Error, Loading using dummy data fixtures), and navigation.
3. **Interactive On-Device Play-Testing & Multi-Screen Audit (Validation Delegation)**:
   - **Delegation to Lower-Intelligence Validation Agent**: Unless the validation is super easy and straightforward, the Coordinator delegates on-device play-testing and UI audits to a lower-intelligence sub-agent (Gemini latest Flash model with low/medium effort: `--agent antigravity --model flash --effort low|medium` or `--agent gemini --model gemini-2.5-flash`).
   - The validation agent wakes and unlocks the test device (`device-wake-unlock.sh`), installs the debug APK, launches the app and the **Shared Component Gallery**, and actively **plays around with the UI** (taps buttons, toggles Light/Dark theme, switches dummy data scenarios, scrolls lists, tests dialogs and back navigation).
   - Runs `device-ui-audit.sh` to verify different screen sizes, resolutions, and densities (`wm size`, `wm density`, `font_scale 1.3`), checking that no text or edges are cut off and that the **status bar**, **display cutout (notch/pinhole)**, and **bottom navigation bar** insets are respected.
   - Reports detailed findings, screenshots, and logs back to the Coordinator, and **immediately cleans up and closes upon completion**.

## 6. Coordinator Rebase Testing, Bug Triage (Fix-on-the-Spot vs. Send-Back) & Cleanup

All final verification is overseen by **you (the Coordinator)** before any code is merged into the main branch:

### Step 1: Rebase onto Target Branch & Test the Rebase on Device

Before merging a worker's branch, rebase the worker's worktree branch onto the latest target branch (`main` / `develop`) so it incorporates any previously merged sibling features:

```bash
git -C "<worker_worktree>" rebase main
```

Unless the validation is super easy and straightforward, the Coordinator dispatches a lower-intelligence validation worker (Gemini latest Flash, low/medium effort) to run the full test suite (`./gradlew lintDebug testDebugUnitTest`) AND install/test the **rebased build on the test device** (`device-verify-gate.sh --run-ui-audit`) to guarantee the rebase introduced zero build, runtime, or visual regressions. Once validation completes and results are reported, the validation worker cleans up and closes immediately.

### Step 2: Coordinator Bug Triage — Fix on the Spot vs. Send Back to Sub-Agent

When Coordinator testing (unit tests, rebase check, interactive device play-testing, or UI inset/density audit) uncovers an issue:

- **Simple / Localized Issue -> Fix on the Spot**:
  - If the defect is small, clear, and localized (for example: a missing window inset modifier, a minor padding or text-overflow tweak, a simple rebase conflict, a missing import, or a small test assertion fix), **fix it directly on the spot** as Coordinator, re-run verification on the test device, and proceed.
- **Complex / Multi-File / Architectural Issue -> Send Back to Original Sub-Agent**:
  - If the defect involves broken business logic, missing feature requirements, failing multi-class flows, or missing test suites, **do not merge**.
  - **Transfer Device Lock Back**: Hand the device lock back along with the task to the sub-agent (`bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" transfer --owner "coordinator" --to "<subagent-name>"`) so the worker has exclusive access to verify fixes on hardware.
  - Dispatch a separate, lower-cost validation worker or instruct the original implementing worker directly, sharing exact failures, logs, screenshots, and minimal reproduction steps. The implementing worker owns the repair and re-submission unless the Coordinator explicitly reassigns it.
  - After the repair, the worker re-runs checks and hands back the deliverable and device lock to the Coordinator. The Coordinator retains the final merge decision.

### Step 3: Post-Pass Merge & Complete Cleanup

Once all tests and on-device rebase checks pass:

1. **Merge the Branch**: Merge the verified worker branch cleanly into the base branch.
2. **Release Device Lock**:
   - Release the exclusive device lock back to the global pool:

   ```bash
   bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" release --owner "coordinator"
   ```

3. **Sub-Agent Keep-Alive Window & Cleanup**:
   - **Post-Submission Keep-Alive**: Do NOT terminate the sub-agent or remove its worktree immediately upon merge. Keep the sub-agent alive for **20 minutes in Manual Mode** or **10 minutes in Auto Mode** for potential revisions.
   - **User Feedback Forwarding**: If the user provides feedback on that specific task while the agent is still alive, forward the feedback directly back to that sub-agent.
   - **Teardown after Keep-Alive Expiration**:
     - **Release Any Claimed Device**: Ensure any device lock claimed or held by the worker is released back to the pool:
       ```bash
       bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" release --owner "<subagent-name>"
       ```
     - **If using Orca**:
       ```bash
       orca orchestration worker-release --dispatch <dispatch_id> --json
       ```
     - **If using Git Worktrees directly**:
       ```bash
       git worktree remove "<worker_worktree>"
       git branch -d "<worker_branch>"
       ```
     - Confirm zero leaked worker terminals, device locks, or stale worktrees remain (`orca orchestration worker-list --run <run_id> --terminal-state reclaimable --json`, `device-pool.sh list`, and `git worktree list`).

## 7. Coordinator Cycle Workflow

Trigger this workflow whenever the user says:
- `sweep`
- `check progress and merge`
- `run the cycle`
- `/cycle`

### Execution Sequence

1. **Check Inbox**:
   - Run `orca orchestration check` and consume all pending messages.
   - Acknowledge each delivery with `orca orchestration check --ack <delivery_id>`.

2. **Inspect Workers**:
   - Read output from active supervised workers:
     ```bash
     orca orchestration worker-read --dispatch <id>
     ```

3. **Validate Completed Tasks**:
   - **Validation Delegation Discipline**:
     - Unless the test/validation is **super easy and straightforward** (e.g., running a single unit test file or inspecting a trivial fix), the Coordinator does **not** perform validation itself.
     - The Coordinator dispatches a lower-intelligence validation worker (for now, **Gemini latest Flash model with low/medium effort**: `--agent antigravity --model flash --effort low|medium` or `--agent gemini --model gemini-2.5-flash`) to run the checks, assemble/install APKs, execute on-device smoke tests, and inspect logs.
     - Once the validation worker finishes and reports back, it **cleans up and closes immediately** (no keep-alive grace period).
   - **Mobile Tasks**:
     - Run tests under lock:
       ```bash
       cd mobile && flock /tmp/dtm-gradle.lock ./gradlew :<module>:allTests
       ```
     - If UI changed:
       - Assemble the debug APK:
         ```bash
         ./gradlew :androidApp:assembleDebug
         ```
       - Install on the connected test device (read dynamically from the test device pool; never hardcode IP or serial):
         ```bash
         TEST_DEVICE=$(bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" list | jq -r '.online_devices[0] // empty')
         adb -s "${TEST_DEVICE:-$ANDROID_SERIAL}" install -r <path_to_apk>
         ```
       - Launch the app, verify logcat has no errors, and capture screenshot.
   - **Backend Tasks**:
     - Run test suite:
       ```bash
       npm --prefix backend/core test -- --run
       ```
     - Run typecheck and lint:
       ```bash
       npm run typecheck
       npm run lint
       ```
   - **Manual vs. Auto Validation & Gating**:
     - **Detailed Report Right Before Testing / Wait**:
       - Right before prompting the user (in Manual Mode) or entering the 2-minute wait (in Auto Mode), the Coordinator must display a comprehensive test briefing:
         1. **What was changed**: Summary of modified files, components, screens, APIs, endpoints, or DB schemas.
         2. **Expected behavior**: Intended user flow, UI states (populated, empty, loading, error), animation curves, and behavior.
         3. **What to test for**: Specific test steps, edge cases, interactions to verify, and verification checkpoints.
         4. **Credentials & Test Prerequisites**: Any credentials, test accounts, mock tokens, API keys, accessible preview links/ports, or test device serials needed to carry out testing.
     - In **Manual Mode**: If design, website UI, or app UI/UX changes are involved, require manual user testing in the exact same manner across app and web. Verify that the worker has deployed the build/preview and notified the Coordinator that tests are ready (with accessible links/preview URLs, local ports, or leased device serials).
     - In **Auto Mode (One-Time Wait Per Delivered Job, Never Looped)**:
       - When a worker's job has completed and delivered waiting for verification, display the detailed report and trigger the 2-minute wait (120 seconds) **strictly once**.
       - **Do not keep running the wait in a loop.** It must never be repeated for the same delivered job.
       - If the user has not responded within the 2-minute window and automated tests pass, consider that job accepted, merge, and **continue directly with the next job**.
       - Repeat one-time verification per delivered job until all jobs across the wave/fleet have completed and verified.
       - **Once all jobs have completed and verified, transition immediately to idle—no more waiting.**
     - *Unless specifically instructed, API changes only require auto testing.*

4. **Merge to Integration Branch**:
   - Ensure the working tree is clean.
   - Run non-fast-forward merge:
     ```bash
     git merge --no-ff <branch> -m "merge: <branch> (Task ...)"
     ```
   - Verify integration ancestry:
     ```bash
     git merge-base --is-ancestor <branch> master
     ```

5. **Post-Merge Smoke Test & Host Discipline**:
   - Run affected tests on `master`.
   - Free memory and stop the Gradle daemon:
     ```bash
     cd mobile && ./gradlew --stop
     ```

6. **Sub-Agent Keep-Alive Window & Automatic Cleanup (AGENTS.md Rule 9)**:
   - **Feature Implementation Workers**:
     - **Post-Submission Keep-Alive**: Do NOT terminate feature sub-agents or remove their worktrees immediately upon merge.
     - Keep feature sub-agents alive for **20 minutes in Manual Mode** or **10 minutes in Auto Mode** for any potential follow-up changes.
     - **Forward User Feedback**: If the user provides feedback on that specific work while the sub-agent is still alive, forward the feedback directly back to that sub-agent (`orca orchestration worker-send --dispatch <id> ...` or harness input) for immediate iteration.
     - **Teardown after Keep-Alive Expiration**:
       - Once the 20-min (Manual) or 10-min (Auto) keep-alive window expires with no further user feedback:
         - Release any claimed test device lock back to the pool:
           ```bash
           bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" release --owner "<subagent-name>"
           ```
         - Release dispatch:
           ```bash
           orca orchestration worker-release --dispatch <id>
           ```
         - Close terminal:
           ```bash
           orca terminal close --terminal <handle> --tab
           ```
         - Terminate orphaned background processes in the worker's worktree directory.
         - Remove worktree & branch:
           ```bash
           wt remove <branch>
           ```
   - **Test & Validation Sub-Agents (Immediate Teardown)**:
     - **No Keep-Alive Window**: Validation sub-agents do not create code or wait for user feedback.
     - As soon as validation is executed, logs/screenshots collected, and the verification report returned to the Coordinator, the validation sub-agent must **immediately clean up and close**:
       1. Release any claimed device lock back to the pool:
          ```bash
          bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" release --owner "<validation-agent-name>"
          ```
       2. Release dispatch:
          ```bash
          orca orchestration worker-release --dispatch <id>
          ```
       3. Close terminal:
          ```bash
          orca terminal close --terminal <handle> --tab
          ```
       4. Terminate orphaned background processes in its worktree directory.
       5. Remove worktree & branch:
          ```bash
          wt remove <branch>
          ```
   - **Verify Complete Cleanup**:
     ```bash
     wt list
     git worktree list
     bash "$SKILL_ROOT/state-droid-remote-device/scripts/device-pool.sh" list
     ```

7. **Document & Suggest Next**:
   - Update `openspec/changes/.../tasks.md` with implementation notes.
   - Present completed work summary to the user and outline the top 2-3 next prioritized tasks.

## Directory Layout

- `SKILL.md`: Orchestration workflow, sub-agent naming, device leasing, rebase testing, triage rules, and cleanup protocol
- `scripts/detect-env.sh`: Probes installed harnesses, spec/memory tools, and device CLIs, updating `~/.config/android-skill-derek/config.json`
- `assets/worker-task-template.md`: 6-Point Worker Task-Spec preamble template (including Component Gallery, Dummy Data, and Signing rules)
- `assets/config.example.json`: Example `~/.config/android-skill-derek/config.json` with long-lived cache settings
