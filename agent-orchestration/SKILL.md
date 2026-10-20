---
name: agent-orchestration
description: Universal multi-agent coordination protocol for parallel sub-agents across isolated git worktrees. Covers Manual vs. Automatic modes, pre-review change reporting, wait policies (one-time wait per delivered job, idle on completion), timeboxed dispatch with two-way estimates, feature worker keep-alive grace periods, quota & model selection routing (Claude, Flash, Argon/Sonnet), bug triage (fix on the spot vs. send back), validation agent delegation discipline (delegating validation to lower-intelligence Gemini Flash agents), immediate validation agent teardown, pluggable validation hooks, and the Coordinator Cycle Workflow (sweep, check progress and merge, run the cycle, /cycle).
---

# Universal Agent Orchestration (`agent-orchestration`)

Coordinate complex multi-agent engineering workflows across parallel sub-agents operating in isolated git worktrees without branch collisions, resource contention, or unverified merges. This skill defines a **framework- and platform-agnostic orchestration protocol** with pluggable verification hooks, compatible with **Orca**, **OpenSpec**, **AgentMemory**, and native CLI sub-agents.

## When to Use

- Coordinating feature development, system refactors, component design, or companion backend/web services across parallel sub-agents
- Operating in **Manual Mode** (active user review for UI/UX changes, deployment notifications) vs. **Automatic Mode** (40-min inactivity fallback, 2-min single wait per delivered job)
- Running the **Coordinator Cycle Workflow** (`sweep`, `check progress and merge`, `run the cycle`, `/cycle`) to drain inbox messages, inspect workers, delegate validation, merge cleanly, run host smoke tests, and execute complete cleanup
- Naming, spawning, and timeboxing isolated git-worktree sub-agents
- Delegating non-trivial validation to lower-intelligence validation agents (Gemini Flash) with immediate teardown
- Triaging bugs (fix simple issues on the spot vs. send back to original worker), and managing feature-worker keep-alive windows for user feedback

---

## 1. Operating Modes, Wait Discipline & Keep-Alive Protocol

The Coordinator operates under one of two operating modes governing validation, merge gating, and worker lifecycles:

### 1.1 Manual Mode (Default on Launch)
- **Active Review**: The user is actively viewing and approving changes.
- **Manual Review Gate**: For every piece of work submitted by a sub-agent, **manual user review is required in addition to automated validation**, whenever **design, website UI, or app UI/UX changes** are involved (treated with identical manual review requirements across app and web).
- **Deployment Notification**: In manual mode, the worker must have changes deployed and explicitly notify the Coordinator that tests are ready (providing accessible links, preview URLs, local ports, or test device serials where suitable) for manual testing.
- **Pre-Review Detailed Report**: Before prompting the user for manual testing/approval, the Coordinator must display a comprehensive test briefing (what was changed, expected behavior, what to test for, and credentials/test prerequisites).
- **Keep-Alive Grace Period (20 Minutes for Feature Workers)**: Feature sub-agents and their worktrees are kept alive for **20 minutes** after submission/merge consideration for any potential changes or follow-up tweaks. *(Note: Test/validation workers do not enter keep-alive; they clean up and close immediately once done).*
- **User Feedback Forwarding**: Any user feedback on a specific piece of work received while the agent is alive is forwarded directly back to that sub-agent.
- **API Changes Exemption**: Unless specifically instructed otherwise by the user, API changes only require automated tests (no manual review/testing gate needed).

### 1.2 Automatic Mode (Unattended / Timed Gating)
- **Automated Validation**: Automated tests run as normal without requiring manual user sign-off.
- **One-Time Wait Per Delivered Job (Strictly Non-Looping)**:
  - When sub-agent work is received, the Coordinator displays the detailed change report and runs automated tests.
  - While running automated tests, the Coordinator triggers a **2-minute wait (120 seconds)** once, prompting the user so they can still perform a manual test if they want.
  - **No Looping**: The Coordinator **must not keep running the wait in a loop**. It triggers strictly once per delivered job.
  - If 120 seconds elapse with no user response and automated tests pass, the work is considered **accepted** and merged. The Coordinator then continues directly to the next delivered job.
- **Fleet Completion to Idle (No More Wait)**:
  - The Coordinator repeats this single one-time verification wait for subsequent worker jobs as they deliver.
  - Once **all jobs** across the fleet have completed and been verified, the Coordinator transitions immediately to **idle** state—**no more waiting, no polling loops**.
- **Keep-Alive Grace Period (10 Minutes for Feature Workers)**: Feature sub-agents and their worktrees are kept alive for **10 minutes** after submission/acceptance for any potential follow-up changes. *(Note: Test/validation workers clean up and close immediately once done).*
- **User Feedback Forwarding**: If the user provides feedback on a specific work during the 10-minute window, forward it directly back to that sub-agent.

### 1.3 Inactivity Timeout & Mode Selection
- **Initial Prompt**: When the user first enters orchestration mode, the Coordinator can ask whether to run in manual or automatic mode.
- **Default**: Launch defaults to **Manual Mode**.
- **40-Minute Inactivity Switch**: If the user has not been interactive for **40 minutes**, the Coordinator automatically switches to **Automatic Mode**.

---

## 2. Sub-Agent Dispatch & Model Selection Protocol

### 2.1 Model Selection, Availability & Dynamic Quota Routing

> **Precedence Rule**: The following model routing rules are only suitable when the respective models are available. **A direct instruction from the user strictly takes precedence over this default routing.**

#### 2.1.1 Model Selection by Task Complexity
- **Harder Tasks & Design Tasks**:
  - Use **Claude** (`--agent claude` or Antigravity's Claude model) for high-complexity engineering challenges, complex algorithms/concurrency, and **any task relating to design** (UI/UX layouts, design tokens, design systems, and visual fidelity).
  - **Antigravity Claude**: Antigravity also has a small allocation of Claude models; use it when suitable for harder tasks or design work.
- **Smaller & Easier Tasks**:
  - Use **Antigravity Flash** (`--agent antigravity --model flash` or `flash_lite`) for simple, lightweight, or highly deterministic tasks (e.g., small bug fixes, boilerplate data classes, straightforward refactors, doc updates).
- **Antigravity Argon (Sonnet-Tier Equivalent)**:
  - Antigravity **Argon** is treated as equivalent to **Sonnet** (`--agent antigravity --model argon`). Use it for mid-to-high complexity implementation tasks.
- **Effort Constraint**:
  - **Do NOT use high effort** (`--effort high` is strictly avoided).
  - Default to `--effort medium` for standard or complex tasks, and `--effort low` for fast, lightweight tasks.

#### 2.1.2 Quota Depletion ("Dry") & Automatic Model Switching
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

#### 2.1.3 Validation Agent Delegation & Immediate Teardown Discipline
- **Coordinator Does Not Validate Directly**: Unless the test or validation task is **super easy and straightforward** (such as running a single trivial unit test or verifying a 1-line typo fix), the Coordinator does **not** perform validation itself.
- **Lower-Intelligence Validation Agent**: The Coordinator dispatches a lower-intelligence agent to run the validation, execute test suites, perform on-device play-testing/audits, verify logs/screenshots, and report back:
  - **Model Specification**: Currently use **Gemini latest Flash model with low/medium effort** (`--agent antigravity --model flash --effort low` or `--effort medium`, or `--agent gemini --model gemini-2.5-flash`).
- **Immediate Cleanup on Completion (No Keep-Alive)**:
  - Unlike feature-authoring workers (which remain alive for 10 or 20 minutes for follow-up adjustments), **any test/validation worker or sub-agent, once its job is done and results are reported, must clean up and close immediately**.
  - Immediate teardown sequence:
    1. Release any claimed hardware or exclusive test locks (`$VALIDATION_LOCK_RELEASE_CMD`).
    2. Release worker dispatch (`orca orchestration worker-release --dispatch <id>`).
    3. Close worker terminal (`orca terminal close --terminal <handle> --tab`).
    4. Terminate any orphaned background processes in the validation worktree.
    5. Remove the validation worktree and branch (`wt remove <branch>`).

### 2.2 Timeboxed Dispatch and Progress Protocol

Every delegated task has a bounded, two-way estimate. Keep only super easy, straightforward validation or localized trivial fixes with the Coordinator; delegate all other validation (to Gemini Flash) and feature development (to suitable feature agents) to sub-agents.

1. **Coordinator dispatch**: state the requested outcome, the expected time range, a checkpoint cadence for work exceeding 30 minutes, and the handoff requirements below.
2. **Worker assessment before implementation**: inspect the task and reply to the Coordinator with its own estimate, assumptions, milestones, and any likely blocker *before* changing code. It must revise that estimate promptly if scope changes.
3. **Coordinator follow-up**: at the worker's estimate plus a reasonable leeway (normally 25%, at least 10 minutes), request a concise status update. Ask earlier if the task misses a stated milestone or its resource lease is blocking another worker. Do not let a worker silently run indefinitely.
4. **Stuck work**: after two missed updates, a repeated blocker, or an estimate materially exceeded without a recovery plan, pause or redirect the task, preserve its worktree/logs, and decide whether to narrow, reassign, or finish the smallest safe part directly.
5. **Completion report**: include estimate versus actual duration, milestones completed, files changed, commands/tests run and results, deployed package/preview URL when applicable, remaining risks, and a clear `ready for coordinator validation` status.

### 2.3 Descriptive Sub-Agent Naming Rule

Always name every sub-agent and its git worktree descriptively after the **feature it is developing** or its **git branch name** so everyone immediately knows what each agent is doing:

- **Good Names**: `feat-component-gallery`, `feat-events-countdown`, `feat-auth-live-sharing`, `fix-pin-session-token`, `qa-rebase-events`
- **Forbidden Names**: Never use opaque labels like `worker-1`, `agent-2`, `subagent-a`, or `temp-worker`.

```bash
# Example: feature-named worktree and sub-agent
orca orchestration worker-start \
  --agent claude \
  --model claude-sonnet-4-6 \
  --effort medium \
  --worktree new-child \
  --name "feat-events-countdown" \
  --prompt "<task spec>"
```

### 2.4 Remote Headless File References

When dispatching Orca workers remotely in headless mode, reference repository files with the relevant path relative to the repository root (for example, `docs/SPEC.md` or `app/src/main/...`). Do not rely on the Coordinator's absolute host paths or ambiguous working-directory-relative paths. Include the repository-root-relative path in the worker prompt, task specification, and any follow-up message that names a file.

---

## 3. Parallel Wave Planning (DAG) & Shared Resources

1. **Track A (Independent Companion / Backend / Web Services — Immediate Parallel Track)**:
   - Self-contained backend or cloud worker directories (`services/*`, `server/*`, `backend/*`) run in parallel with foundational client work.
2. **Track B — Wave 0 (Sequential Gate: Foundation, Theme, Component Gallery, Seed Data)**:
   - Implement core design language tokens, layout insets, seed/dummy data fixtures, and component showcase before fan-out.
   - Verify, then merge Wave 0 into the base branch before launching Wave 1.
3. **Track B — Wave 1+ (Concurrent Feature Fan-Out — Cap at 4 Named Workers)**:
   - Spawn up to 4 feature-named sub-agents in isolated child worktrees. Each feature sub-agent registers new shared UI components and provides deterministic fixtures for its screens.

### 3.1 Exclusive Hardware & Shared Resource Leases
- **Single-Use Exclusivity**: When a scarce physical device, port, or environment lock is claimed by the Coordinator or a sub-agent, it is claimed exclusively for single use.
- **Active Testing Only (No Development Holding)**: Locks must never be held during active code development. Claim the lock strictly during active test execution/deployment, and release or transfer it immediately when testing concludes.
- **Lock Transfer on Delivery**: When a worker finishes and hands off a build deliverable, it transfers the lock to the Coordinator (`transfer --owner "<worker>" --to "coordinator"`).
- **Lock Return on Rejection**: If work is rejected for fixes, the lock is transferred back along with the task.

---

## 4. Worker Handoff Must Be Test-Ready

Before a worker hands off a deliverable, it must make the current branch ready for Coordinator validation:

- Run the relevant fast checks and assigned test suites.
- **Design, Website UI & App UI/UX Changes**:
  - In **Manual Mode**, deploy the changes (to assigned test device or preview server) and explicitly notify the Coordinator that tests are ready (providing accessible preview links/ports or test device serials) for manual user testing.
  - In **Auto Mode**, deploy and prepare reproducible entry points for automated validation.
- **Pre-Review 4-Part Summary**:
  The worker's handoff message must provide the exact details the Coordinator displays to the user:
  1. **What was changed**: Modified files, UI components, screens, APIs, endpoints, or DB schemas.
  2. **Expected behavior**: Intended user flow, UI states (populated, empty, loading, error), animation transitions, and behavior.
  3. **What to test for**: Specific test steps, edge cases, and verification checkpoints.
  4. **Credentials & Test Prerequisites**: Any credentials, test accounts, mock tokens, API keys, accessible preview links/ports, or test device serials needed.
- **Keep-Alive Readiness**:
  - Feature sub-agents remain alive post-submission (**20 minutes in Manual Mode**, **10 minutes in Auto Mode**) to receive and apply any forwarded user feedback.

---

## 5. Bug Triage & Rebase Verification

All final verification is overseen by **you (the Coordinator)** before any code is merged into the main branch:

### Step 1: Rebase onto Target Branch
Before merging a worker's branch, rebase the worker's worktree branch onto the latest target branch (`main` / `develop`) so it incorporates any previously merged sibling features:

```bash
git -C "<worker_worktree>" rebase main
```

Unless the validation is super easy and straightforward, the Coordinator dispatches a lower-intelligence validation worker (Gemini latest Flash, low/medium effort) to run the full test suite and smoke-test the rebased build. Once validation completes and results are reported, the validation worker cleans up and closes immediately.

### Step 2: Bug Triage — Fix on the Spot vs. Send Back
- **Simple / Localized Issue -> Fix on the Spot**:
  - If the defect is small, clear, and localized (e.g. minor padding tweak, simple rebase conflict, missing import, or small test assertion fix), **fix it directly on the spot** as Coordinator, re-run verification, and proceed.
- **Complex / Architectural Issue -> Send Back to Sub-Agent**:
  - If the defect involves broken business logic, missing feature requirements, or failing multi-class flows, **do not merge**.
  - Transfer resource/device locks back to the worker.
  - Send the defect back to the implementing worker with exact logs, reproduction steps, and screenshots. The implementing worker owns the fix while still in its keep-alive window.

---

## 6. Coordinator Cycle Workflow

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
     - Unless the test/validation is **super easy and straightforward** (e.g., running a single unit test file or inspecting a trivial fix), the Coordinator does **not** perform validation directly.
     - The Coordinator dispatches a lower-intelligence validation worker (for now, **Gemini latest Flash model with low/medium effort**: `--agent antigravity --model flash --effort low|medium` or `--agent gemini --model gemini-2.5-flash`) to run the checks, assemble artifacts, execute smoke tests, and inspect logs.
     - Once the validation worker finishes and reports back, it **cleans up and closes immediately** (no keep-alive grace period).
   - **Pluggable Test Execution Hooks**:
     - Run project test command under any required lock:
       ```bash
       ${VALIDATION_TEST_CMD:-npm test}
       ```
     - If UI changed:
       - Run build/deploy command:
         ```bash
         ${VALIDATION_DEPLOY_CMD:-npm run build}
         ```
       - Run runtime smoke checks or screenshot capture:
         ```bash
         ${VALIDATION_SMOKE_CMD}
         ```
   - **Manual vs. Auto Validation & Gating**:
     - **Detailed Report Right Before Testing / Wait**:
       - Right before prompting the user (in Manual Mode) or entering the 2-minute wait (in Auto Mode), the Coordinator displays the comprehensive 4-part test briefing (what changed, expected behavior, what to test for, prerequisites/credentials).
     - **In Manual Mode**: If UI/UX changes are involved, require manual user testing. Ensure the worker has deployed the preview/build and provided accessible links or device serials.
     - **In Auto Mode (One-Time Wait Per Delivered Job, Never Looped)**:
       - Trigger the 2-minute wait (120 seconds) **strictly once**.
       - If the user has not responded within 120 seconds and automated tests pass, consider that job accepted, merge, and continue directly with the next job.
       - **Once all jobs across the fleet have completed and verified, transition immediately to idle—no more waiting.**
     - *API changes only require automated tests unless specifically instructed otherwise.*

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
   - Run affected tests on the integration branch.
   - Run post-merge cleanup command to free memory / background daemons:
     ```bash
     ${POST_MERGE_CLEANUP_CMD}
     ```

6. **Sub-Agent Keep-Alive Window & Automatic Cleanup (AGENTS.md Rule 9)**:
   - **Feature Implementation Workers**:
     - **Post-Submission Keep-Alive**: Do NOT terminate feature sub-agents or remove their worktrees immediately upon merge.
     - Keep feature sub-agents alive for **20 minutes in Manual Mode** or **10 minutes in Auto Mode** for any potential follow-up changes.
     - **Forward User Feedback**: If the user provides feedback on that specific work while the sub-agent is still alive, forward the feedback directly back to that sub-agent (`orca orchestration worker-send --dispatch <id> ...` or harness input) for immediate iteration.
     - **Teardown after Keep-Alive Expiration**:
       - Once the 20-min (Manual) or 10-min (Auto) keep-alive window expires with no further user feedback:
         - Release any claimed resource or test device lock.
         - Release dispatch (`orca orchestration worker-release --dispatch <id>`).
         - Close terminal (`orca terminal close --terminal <handle> --tab`).
         - Terminate orphaned background processes in the worker's worktree directory.
         - Remove worktree & branch (`wt remove <branch>`).
   - **Test & Validation Sub-Agents (Immediate Teardown)**:
     - **No Keep-Alive Window**: Validation sub-agents do not create code or wait for user feedback.
     - As soon as validation is executed, logs/screenshots collected, and the verification report returned to the Coordinator, the validation sub-agent must **immediately clean up and close**:
       1. Release any claimed device/resource locks.
       2. Release dispatch (`orca orchestration worker-release --dispatch <id>`).
       3. Close terminal (`orca terminal close --terminal <handle> --tab`).
       4. Terminate orphaned background processes in its worktree directory.
       5. Remove worktree & branch (`wt remove <branch>`).
   - **Verify Complete Cleanup**:
     ```bash
     wt list
     git worktree list
     ```

7. **Document & Suggest Next**:
   - Update task tracking specs with implementation notes.
   - Present completed work summary to the user and outline the top 2-3 next prioritized tasks.

---

## Directory Layout

- `SKILL.md`: Universal orchestration protocol, sub-agent naming, keep-alive windows, validation delegation, and cleanup
- `scripts/detect-env.sh`: Probes installed harnesses (`orca`, etc.), sub-agent CLIs, spec tools, and memory services
- `assets/worker-task-template.md`: Universal 7-Point Worker Task-Spec preamble template
- `assets/config.example.json`: Example `~/.config/agent-orchestration/config.json`
